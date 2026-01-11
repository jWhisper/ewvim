import Foundation
import ApplicationServices
import Carbon

class KeySimulator {
  /// Event tap location that bypasses our keyboard monitor
  /// In C: kCGAnnotatedSessionEventTap (rawValue: 2)
  private static let bypassTapLocation = CGEventTapLocation(rawValue: 2)!

  /// Simulates a key press. Uses kCGAnnotatedSessionEventTap to bypass our keyboard monitor.
  static func press(keyCode: CGKeyCode, modifiers: UInt64 = 0) {
    let modStr = modifiers != 0 ? " modifiers=0x\(String(modifiers, radix: 16))" : ""
    print("      ⌨️ KeySimulator pressing keyCode=\(keyCode) (\(KeyboardMapping.keyToString(Int64(keyCode))))\(modStr)")

    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(
      keyboardEventSource: source,
      virtualKey: keyCode,
      keyDown: true
    )
    keyDown?.flags = CGEventFlags(rawValue: modifiers)

    // Use annotatedSessionEventTap to bypass our keyboard monitor
    // This prevents synthetic events from being intercepted
    keyDown?.post(tap: bypassTapLocation)

    let keyUp = CGEvent(
      keyboardEventSource: source,
      virtualKey: keyCode,
      keyDown: false
    )
    keyUp?.flags = CGEventFlags(rawValue: modifiers)

    keyUp?.post(tap: bypassTapLocation)

    Thread.sleep(forTimeInterval: 0.005)
  }

  static func typeWithoutCapture(forText text: String) {
    for character in text {
      if let keyCode = KeyboardMapping.charToKeyCode(character) {
        let modifiers = KeyboardMapping.modifiersForCharacter(character)
        press(keyCode: keyCode, modifiers: modifiers)
      }
    }
    Thread.sleep(forTimeInterval: 0.01)
  }

  static func type(_ text: String) {
    for character in text {
      if let keyCode = KeyboardMapping.charToKeyCode(character) {
        let modifiers = KeyboardMapping.modifiersForCharacter(character)
        press(keyCode: keyCode, modifiers: modifiers)
      }
    }
  }
}
