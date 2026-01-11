import Foundation
import ApplicationServices
import Carbon
import Cocoa

class KeyboardMonitor {
  private var eventTap: CFMachPort?
  private var runLoopSource: CFRunLoopSource?
  private var keyHandler: (String, CGKeyCode) -> Bool
  private var isEnabled = false
  private var isTerminating = false
  var onQuit: (() -> Void)?

  init(handler: @escaping (String, CGKeyCode) -> Bool) {
    self.keyHandler = handler
  }

  func willTerminate() {
    isTerminating = true
  }

  func start() {
    let eventMask = (1 << CGEventType.keyDown.rawValue)

    guard let eventTap = CGEvent.tapCreate(
      tap: .cgSessionEventTap,
      place: .headInsertEventTap,
      options: .defaultTap,
      eventsOfInterest: CGEventMask(eventMask),
      callback: { proxy, type, event, refcon in
        guard let refcon = refcon else {
          return Unmanaged.passUnretained(event)
        }

        let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon).takeUnretainedValue()

        // Don't handle events if we're terminating
        if monitor.isTerminating {
          return Unmanaged.passUnretained(event)
        }

        if type == .keyDown {
          let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
          let flags = event.flags.rawValue

          // Check for Ctrl+C to quit
          // 'c' keyCode is 0x08, control key bit is 0x10000
          if keyCode == 0x08 && (flags & 0x10000) != 0 {
            print("🛑 Ctrl+C detected - quitting application")
            monitor.onQuit?()
            return Unmanaged.passUnretained(event)
          }

          if KeyboardMapping.shouldIgnoreKey(keyCode) {
            return Unmanaged.passUnretained(event)
          }

          let keyString = monitor.getKeyString(from: event)
          if !keyString.isEmpty {
            let shouldIntercept = monitor.handleKeyEvent(keyString, keyCode: CGKeyCode(keyCode))
            if shouldIntercept {
              return nil
            }
          }
        }

        return Unmanaged.passUnretained(event)
      },
      userInfo: Unmanaged.passUnretained(self).toOpaque()
    ) else {
      print("Failed to create event tap")
      return
    }

    self.eventTap = eventTap

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
    self.runLoopSource = runLoopSource
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)

    CGEvent.tapEnable(tap: eventTap, enable: true)
    isEnabled = true
  }

  func stop() {
    guard let eventTap = eventTap else { return }

    CGEvent.tapEnable(tap: eventTap, enable: false)

    if let runLoopSource = runLoopSource {
      CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
      self.runLoopSource = nil
    }

    self.eventTap = nil
    isEnabled = false
  }

  private func handleKeyEvent(_ keyString: String, keyCode: CGKeyCode) -> Bool {
    if isTerminating {
      return false  // Don't intercept during shutdown
    }
    if Thread.isMainThread {
      return self.keyHandler(keyString, keyCode)
    } else {
      var result = false
      // Use async with a small timeout instead of sync to avoid deadlock
      let semaphore = DispatchSemaphore(value: 0)
      DispatchQueue.main.async { [weak self] in
        guard let self = self, !self.isTerminating else {
          semaphore.signal()
          return
        }
        result = self.keyHandler(keyString, keyCode)
        semaphore.signal()
      }
      _ = semaphore.wait(timeout: .now() + 0.1)
      return result
    }
  }

  private func getKeyString(from event: CGEvent) -> String {
    // Try to get the Unicode string directly from the event
    var buffer = [UniChar](repeating: 0, count: 256)
    var actualLength: Int = 0

    buffer.withUnsafeMutableBufferPointer { bufferPtr in
      event.keyboardGetUnicodeString(
        maxStringLength: 256,
        actualStringLength: &actualLength,
        unicodeString: bufferPtr.baseAddress
      )
    }

    if actualLength > 0 {
      let str = String(utf16CodeUnits: &buffer, count: actualLength)
      // Preserve case for commands like G vs g
      return str
    }

    // Fallback to keyCode-based mapping for special keys (ESC, arrows, etc.)
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    return KeyboardMapping.keyToString(keyCode)
  }
}
