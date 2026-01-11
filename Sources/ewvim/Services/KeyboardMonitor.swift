import Foundation
import ApplicationServices
import Carbon

class KeyboardMonitor {
  private var eventTap: CFMachPort?
  private var keyHandler: (String) -> Void
  private var isEnabled = false

  init(handler: @escaping (String) -> Void) {
    self.keyHandler = handler
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

        if type == .keyDown {
          let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

          if monitor.shouldIgnoreKey(keyCode: Int64(keyCode)) {
            return Unmanaged.passUnretained(event)
          }

          let keyString = monitor.keyToString(keyCode)
          print("🔹 Key captured: \(keyString) (keyCode: \(keyCode))")
          monitor.handleKeyEvent(event)
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
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

    CGEvent.tapEnable(tap: eventTap, enable: true)
    isEnabled = true

    CFRunLoopRun()
  }

  func stop() {
    guard let eventTap = eventTap else { return }

    CGEvent.tapEnable(tap: eventTap, enable: false)
    CFRunLoopStop(CFRunLoopGetCurrent())

    self.eventTap = nil
    isEnabled = false
  }

  private func handleKeyEvent(_ event: CGEvent) {
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let keyString = keyToString(keyCode)

    if !keyString.isEmpty {
      DispatchQueue.main.async {
        self.keyHandler(keyString)
      }
    }
  }

  private func shouldIgnoreKey(keyCode: Int64) -> Bool {
    if keyCode >= 0x3A && keyCode <= 0x64 {
      print("🚫 Ignoring function key: \(keyCode) (0x\(String(format: "%02X", keyCode))")
      return true
    }

    if keyCode == 0x36 || keyCode == 0x37 || keyCode == 0x38 {
      print("🚫 Ignoring modifier key: \(keyCode) (0x\(String(format: "%02X", keyCode))")
      return true
    }

    return false
  }

  private func keyToString(_ keyCode: Int64) -> String {
    let keyMap: [Int64: String] = [
      0x00: "a",
      0x01: "s",
      0x02: "d",
      0x03: "f",
      0x04: "h",
      0x05: "g",
      0x06: "z",
      0x07: "x",
      0x08: "c",
      0x09: "v",
      0x0A: "b",
      0x0B: "q",
      0x0C: "w",
      0x0D: "e",
      0x0E: "r",
      0x0F: "y",
      0x10: "t",
      0x11: "1",
      0x12: "2",
      0x13: "3",
      0x14: "4",
      0x15: "6",
      0x16: "5",
      0x17: "=",
      0x18: "9",
      0x19: "7",
      0x1A: "-",
      0x1B: "8",
      0x1C: "0",
      0x1D: "]",
      0x1E: "o",
      0x1F: "u",
      0x20: "[",
      0x21: "i",
      0x22: "p",
      0x23: "Return",
      0x24: "l",
      0x25: "j",
      0x26: "'",
      0x27: "k",
      0x28: ";",
      0x29: "\\",
      0x2A: ",",
      0x2B: "/",
      0x2C: "n",
      0x2D: "m",
      0x2E: ".",
      0x2F: "Tab",
      0x30: "Space",
      0x31: "`",
      0x32: "Backspace",
      0x33: "Escape",
      0x34: "Command",
      0x35: "Shift",
      0x36: "CapsLock",
      0x37: "Option",
      0x38: "Control",
      0x3A: "F17",
      0x3B: "Decimal",
      0x3C: "*",
      0x3D: "+",
      0x3E: "Clear",
      0x3F: "/",
      0x40: "Enter",
      0x41: "-",
      0x42: "=",
      0x43: "0",
      0x44: "1",
      0x45: "2",
      0x46: "3",
      0x47: "4",
      0x48: "5",
      0x49: "6",
      0x4A: "7",
      0x4B: "8",
      0x4C: "9",
      0x4E: "Underscore",
      0x4F: "Decimal",
      0x50: "=",
      0x51: "0",
      0x52: "1",
      0x53: "2",
      0x54: "3",
      0x55: "4",
      0x56: "5",
      0x57: "6",
      0x58: "7",
      0x59: "8",
      0x5A: "9",
      0x5B: "F11",
      0x5C: "F12",
      0x5D: "F13",
      0x5E: "F14",
      0x5F: "F15",
      0x60: "F16",
      0x61: "F17",
      0x62: "F18",
      0x63: "F19",
      0x64: "F20",
      0x65: "F5",
      0x66: "F6",
      0x67: "F7",
      0x68: "F3",
      0x69: "F8",
      0x6A: "F9",
      0x6B: "F11",
      0x6C: "F13",
      0x6D: "F14",
      0x6E: "F10",
      0x6F: "F12",
      0x70: "F15",
      0x71: "Insert",
      0x72: "Home",
      0x73: "PageUp",
      0x74: "ForwardDelete",
      0x75: "End",
      0x76: "PageDown",
      0x77: "F6",
      0x78: "F7",
      0x79: "F8",
      0x7A: "F9",
      0x7B: "F11",
      0x7C: "F12",
      0x7D: "Left",
      0x7E: "Right",
      0x7F: "Down",
      0x80: "Up"
    ]

    return keyMap[keyCode] ?? ""
  }
}