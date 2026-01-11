import Foundation

class VimCommandProcessor {
  func parseCommand(_ buffer: String) -> VimCommand {
    let command = String(buffer)

    // Check for ESC command first
    if command == "ESC" {
      return .exitToNormalMode
    }

    // Handle multi-character operators (dd, cc, yy, gg)
    if command.count >= 2 {
      let chars = Array(command)
      let first = chars[0]
      let second = chars[1]

      // Double operator commands: dd, cc, yy
      if first == second {
        if first == Character("d") { return .deleteLine }
        if first == Character("c") { return .changeLine }
        if first == Character("y") { return .yankLine }
      }

      // gg: go to first line
      if first == Character("g") && second == Character("g") {
        return .goToFirstLine
      }
    }

    // Handle single character commands
    if command.count == 1 {
      let char = command.first!

      // Motion commands
      if char == Character("h") { return .moveLeft }
      if char == Character("j") { return .moveDown }
      if char == Character("k") { return .moveUp }
      if char == Character("l") { return .moveRight }
      if char == Character("w") { return .moveWordForward }
      if char == Character("e") { return .moveWordEndForward }
      if char == Character("b") { return .moveWordBackward }
      if char == Character("G") {
        print("🎯 VimCommandProcessor: matched 'G' -> .goToLastLine")
        return .goToLastLine
      }

      // Insert mode commands
      if char == Character("i") { return .enterInsertMode }
      if char == Character("a") { return .enterInsertAfterCursor }
      if char == Character("I") { return .enterInsertLineBegin }
      if char == Character("A") { return .enterInsertLineEnd }
      if char == Character("o") { return .enterInsertLineBelow }
      if char == Character("O") { return .enterInsertLineAbove }

      // Visual mode
      if char == Character("v") { return .enterVisualMode }
      if char == Character("V") { return .enterVisualLineMode }

      // Delete commands
      if char == Character("x") { return .deleteChar }
      if char == Character("D") { return .deleteToEndOfLine }

      // Change commands
      if char == Character("s") { return .changeChar }
      if char == Character("C") { return .changeToEndOfLine }

      // Yank commands
      if char == Character("y") { return .yankChar }

      // Paste commands
      if char == Character("p") { return .pasteAfter }
      if char == Character("P") { return .pasteBefore }

      // Undo/Redo
      if char == Character("u") { return .undo }
      if char == Character("r") { return .redo }

      // Operators that need more input (include g for gg)
      if char == Character("g") || char == Character("d") || char == Character("c") {
        return .unknown  // Waiting for second character
      }

      // Unknown single character - intercept in Normal mode
      return .unknown
    }

    // Handle count + motion (e.g., "10j", "5h")
    let count = extractCount(from: command)
    if let count = count, count > 0 {
      let countStr = String(count)
      if command.count > countStr.count {
        let motionIndex = command.index(command.startIndex, offsetBy: countStr.count)
        let motionChar = command[motionIndex]

        // Check for dd combination first
        if command.count > countStr.count + 1 {
          let nextIndex = command.index(after: motionIndex)
          if motionChar == Character("d") && command[nextIndex] == Character("d") {
            return .deleteLine
          }
        }

        // Count + motion commands
        if motionChar == Character("h") { return .moveLeft }
        if motionChar == Character("j") { return .moveDown }
        if motionChar == Character("k") { return .moveUp }
        if motionChar == Character("l") { return .moveRight }
        if motionChar == Character("w") { return .moveWordForward }
        if motionChar == Character("e") { return .moveWordEndForward }
        if motionChar == Character("b") { return .moveWordBackward }
        if motionChar == Character("x") { return .deleteChar }
      }
    }

    return .unknown
  }

  func extractCount(from command: String) -> Int? {
    let numericPrefix = command.prefix(while: { $0.isNumber })
    return numericPrefix.isEmpty ? nil : Int(numericPrefix)
  }
}
