import Foundation
import ApplicationServices
import Carbon

class KeySimulator {
  static func press(keyCode: CGKeyCode, modifiers: UInt64 = 0) {
    let source = CGEventSource(stateID: .hidSystemState)

    let keyDown = CGEvent(
      keyboardEventSource: source,
      virtualKey: keyCode,
      keyDown: true
    )
    keyDown?.flags = CGEventFlags(rawValue: modifiers)
    keyDown?.post(tap: .cghidEventTap)

    let keyUp = CGEvent(
      keyboardEventSource: source,
      virtualKey: keyCode,
      keyDown: false
    )
    keyUp?.flags = CGEventFlags(rawValue: modifiers)
    keyUp?.post(tap: .cghidEventTap)

    Thread.sleep(forTimeInterval: 0.005)
  }

  static func type(_ text: String) {
    for character in text {
      if let keyCode = characterToKeyCode(character) {
        let modifiers = characterToModifiers(character)
        press(keyCode: keyCode, modifiers: modifiers)
      }
    }
  }

  private static func characterToKeyCode(_ character: Character) -> CGKeyCode? {
    let keyMap: [Character: CGKeyCode] = [
      "a": 0x00,
      "b": 0x0B,
      "c": 0x08,
      "d": 0x02,
      "e": 0x0E,
      "f": 0x03,
      "g": 0x05,
      "h": 0x04,
      "i": 0x22,
      "j": 0x26,
      "k": 0x28,
      "l": 0x25,
      "m": 0x2E,
      "n": 0x2D,
      "o": 0x1F,
      "p": 0x23,
      "q": 0x0C,
      "r": 0x0F,
      "s": 0x01,
      "t": 0x11,
      "u": 0x20,
      "v": 0x09,
      "w": 0x0D,
      "x": 0x07,
      "y": 0x10,
      "z": 0x06,
      "0": 0x1D,
      "1": 0x12,
      "2": 0x13,
      "3": 0x14,
      "4": 0x15,
      "5": 0x17,
      "6": 0x16,
      "7": 0x1A,
      "8": 0x1C,
      "9": 0x19,
      " ": 0x31,
      "-": 0x1B,
      "=": 0x18,
      "[": 0x21,
      "]": 0x1E,
      "\\": 0x2A,
      ";": 0x29,
      "'": 0x27,
      ",": 0x2B,
      ".": 0x2F,
      "/": 0x2C,
      "\n": 0x24,
      "\t": 0x30
    ]

    return keyMap[character]
  }

  private static func characterToModifiers(_ character: Character) -> UInt64 {
    if character.isUppercase {
      return 1 << 17 // shiftKeyMask
    }
    return 0
  }
}