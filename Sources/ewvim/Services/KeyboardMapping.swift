import Foundation
import Carbon

/// Centralized keyboard mappings for ewvim
class KeyboardMapping {
  // KeyCode -> Character (monitoring)
  static let keyCodeToString: [CGKeyCode: String] = [
    // Letters
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
    0x1E: "o",
    0x1F: "u",
    0x20: "[",
    0x21: "i",
    0x22: "p",
    0x24: "l",
    0x25: "j",
    0x27: "k",
    0x2C: "n",
    0x2D: "m",
    // Numbers
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
    // Special keys
    0x23: "Return",
    0x26: "'",
    0x28: ";",
    0x29: "\\",
    0x2A: ",",
    0x2B: "/",
    0x2E: ".",
    0x2F: "Tab",
    0x30: "Space",
    0x31: "`",
    0x32: "Backspace",
    0x33: "Delete",
    0x34: "Return",
    0x35: "ESC",
    0x36: "CapsLock",
    0x37: "Option",
    0x38: "Control",
    // Numpad
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
    // Function keys
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
    // Arrows
    0x7B: "Left",
    0x7C: "Right",
    0x7D: "Down",
    0x7E: "Up",
    0x7F: "Down",
    0x80: "Up"
  ]

  // Character -> KeyCode (simulation)
  static let characterToKeyCode: [Character: CGKeyCode] = [
    "a": 0x00,
    "b": 0x0B,
    "c": 0x08,
    "d": 0x02,
    "e": 0x0E,
    "f": 0x03,
    "g": 0x05,
    "h": 0x04,
    "i": 0x21,
    "j": 0x25,
    "k": 0x27,
    "l": 0x24,
    "m": 0x2D,
    "n": 0x2C,
    "o": 0x1E,
    "p": 0x22,
    "q": 0x0C,
    "r": 0x0F,
    "s": 0x01,
    "t": 0x11,
    "u": 0x1F,
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
    "[": 0x20,
    "]": 0x1D,
    "\\": 0x29,
    ";": 0x28,
    "'": 0x26,
    ",": 0x2A,
    ".": 0x2E,
    "/": 0x2B,
    "\n": 0x23,
    "\t": 0x2F
  ]

  // Special key codes
  static let escKey: CGKeyCode = 0x35
  static let spaceKey: CGKeyCode = 0x31

  // Arrow key codes
  static let leftArrow: CGKeyCode = 0x7B
  static let rightArrow: CGKeyCode = 0x7C
  static let downArrow: CGKeyCode = 0x7D
  static let upArrow: CGKeyCode = 0x7E

  // Command and navigation keys
  static let homeKey: CGKeyCode = 0x74
  static let endKey: CGKeyCode = 0x75
  static let pageUpKey: CGKeyCode = 0x73
  static let pageDownKey: CGKeyCode = 0x76
  static let forwardDeleteKey: CGKeyCode = 0x75
  static let backspaceKey: CGKeyCode = 0x33
  static let tabKey: CGKeyCode = 0x22
  static let returnKey: CGKeyCode = 0x23

  // Modifier key masks
  static let cmdKey: UInt64 = 0x100000
  static let shiftKey: UInt64 = 0x20000
  static let optionKey: UInt64 = 0x80000
  static let controlKey: UInt64 = 0x10000

  // Check if a keyCode should be ignored (modifiers, function keys)
  static func shouldIgnoreKey(_ keyCode: Int64) -> Bool {
    // Function keys F1-F20
    if keyCode >= 0x3A && keyCode <= 0x64 {
      return true
    }
    // Modifier keys (Cmd, Option, Control, CapsLock)
    if keyCode == 0x36 || keyCode == 0x37 || keyCode == 0x38 {
      return true
    }
    // Arrow keys
    if keyCode == 0x7B || keyCode == 0x7C || keyCode == 0x7D || keyCode == 0x7E {
      return true
    }
    return false
  }

  // Convert keyToString
  static func keyToString(_ keyCode: Int64) -> String {
    return keyCodeToString[CGKeyCode(keyCode)] ?? ""
  }

  // Convert char to keyCode
  static func charToKeyCode(_ char: Character) -> CGKeyCode? {
    return characterToKeyCode[char]
  }

  // Get modifiers for uppercase characters
  static func modifiersForCharacter(_ char: Character) -> UInt64 {
    return char.isUppercase ? shiftKey : 0
  }
}
