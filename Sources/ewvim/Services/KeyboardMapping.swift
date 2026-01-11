import Foundation
import Carbon

/// Centralized keyboard mappings for ewvim
/// Based on official Apple Key Codes: https://eastmanreference.com/complete-list-of-applescript-key-codes
class KeyboardMapping {
  // KeyCode -> Character (monitoring)
  static let keyCodeToString: [CGKeyCode: String] = [
    // Letters (A-Z) - Official Apple Key Codes
    0x00: "a",  // A = 0
    0x01: "s",  // S = 1
    0x02: "d",  // D = 2
    0x03: "f",  // F = 3
    0x04: "h",  // H = 4
    0x05: "g",  // G = 5
    0x06: "z",  // Z = 6
    0x07: "x",  // X = 7
    0x08: "c",  // C = 8
    0x09: "v",  // V = 9
    0x0A: "",   // (reserved)
    0x0B: "b",  // B = 11
    0x0C: "q",  // Q = 12
    0x0D: "w",  // W = 13
    0x0E: "e",  // E = 14
    0x0F: "r",  // R = 15
    0x10: "y",  // Y = 16
    0x11: "t",  // T = 17
    0x1F: "o",  // O = 31
    0x20: "u",  // U = 32
    0x22: "i",  // I = 34
    0x23: "p",  // P = 35
    0x25: "l",  // L = 37
    0x26: "j",  // J = 38
    0x28: "k",  // K = 40
    0x2D: "n",  // N = 45
    0x2E: "m",  // M = 46
    // Numbers (0-9) - Official Apple Key Codes
    0x12: "1",  // 1 = 18
    0x13: "2",  // 2 = 19
    0x14: "3",  // 3 = 20
    0x15: "4",  // 4 = 21
    0x16: "6",  // 6 = 22
    0x17: "5",  // 5 = 23
    0x18: "=",  // = = 24
    0x19: "9",  // 9 = 25
    0x1A: "7",  // 7 = 26
    0x1B: "-",  // - = 27
    0x1C: "8",  // 8 = 28
    0x1D: "0",  // 0 = 29
    // Other keys
    0x1E: "]",
    0x21: "[",
    0x24: "Return",
    0x27: "'",
    0x29: ";",
    0x2A: "\\",
    0x2B: ",",
    0x2C: "/",
    0x2F: ".",
    0x30: "Tab",
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

  // Character -> KeyCode (simulation) - Official Apple Key Codes
  static let characterToKeyCode: [Character: CGKeyCode] = [
    // Letters (A-Z)
    "a": 0x00,  // A = 0
    "b": 0x0B,  // B = 11
    "c": 0x08,  // C = 8
    "d": 0x02,  // D = 2
    "e": 0x0E,  // E = 14
    "f": 0x03,  // F = 3
    "g": 0x05,  // G = 5
    "h": 0x04,  // H = 4
    "i": 0x22,  // I = 34
    "j": 0x26,  // J = 38
    "k": 0x28,  // K = 40
    "l": 0x25,  // L = 37
    "m": 0x2E,  // M = 46
    "n": 0x2D,  // N = 45
    "o": 0x1F,  // O = 31
    "p": 0x23,  // P = 35
    "q": 0x0C,  // Q = 12
    "r": 0x0F,  // R = 15
    "s": 0x01,  // S = 1
    "t": 0x11,  // T = 17
    "u": 0x20,  // U = 32
    "v": 0x09,  // V = 9
    "w": 0x0D,  // W = 13
    "x": 0x07,  // X = 7
    "y": 0x10,  // Y = 16
    "z": 0x06,  // Z = 6
    // Numbers (0-9)
    "0": 0x1D,  // 0 = 29
    "1": 0x12,  // 1 = 18
    "2": 0x13,  // 2 = 19
    "3": 0x14,  // 3 = 20
    "4": 0x15,  // 4 = 21
    "5": 0x17,  // 5 = 23
    "6": 0x16,  // 6 = 22
    "7": 0x1A,  // 7 = 26
    "8": 0x1C,  // 8 = 28
    "9": 0x19,  // 9 = 25
    // Other characters
    " ": 0x30,
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
  static let tabKey: CGKeyCode = 0x2F
  static let returnKey: CGKeyCode = 0x24

  // Character key codes (for common shortcuts)
  static let cKey: CGKeyCode = 0x08
  static let vKey: CGKeyCode = 0x09
  static let zKey: CGKeyCode = 0x06
  static let eKey: CGKeyCode = 0x0E

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
