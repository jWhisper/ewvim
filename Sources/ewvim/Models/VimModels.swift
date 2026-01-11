import Foundation

enum VimMode: String {
  case normal = "normal"
  case insert = "insert"
  case visual = "visual"
  case visualLine = "visualLine"
}

struct VimState {
  var mode: VimMode
  var commandBuffer: String
  var count: Int
  var register: Character?
  var registerValue: String?

  init() {
    self.mode = .insert
    self.commandBuffer = ""
    self.count = 0
    self.register = nil
    self.registerValue = nil
  }
}

enum VimCommand {
  case moveLeft
  case moveRight
  case moveUp
  case moveDown
  case moveWordForward        // w - move to start of next word
  case moveWordEndForward    // e - move to end of next word
  case moveWordBackward      // b - move to previous word start
  case enterInsertMode
  case enterInsertAfterCursor  // a - insert after cursor
  case enterInsertLineBegin    // I - insert at line beginning
  case enterInsertLineEnd      // A - insert at line end
  case enterInsertLineBelow    // o - open new line below
  case enterInsertLineAbove    // O - open new line above
  case enterVisualMode
  case enterVisualLineMode
  case exitToNormalMode
  case goToFirstLine
  case goToLastLine
  case deleteChar              // x - delete character
  case deleteLine              // dd - delete line
  case deleteToEndOfLine       // D - delete to end of line
  case changeChar              // s - substitute character
  case changeLine              // cc - change line
  case changeToEndOfLine       // C - change to end of line
  case yankChar                // y - yank (with motion)
  case yankLine                // yy / Y - yank line
  case pasteAfter              // p - paste after cursor
  case pasteBefore             // P - paste before cursor
  case undo
  case redo
  case unknown
}

enum VimError: Error, LocalizedError {
  case accessibilityNotEnabled
  case invalidCommand
  case executionFailed(String)

  var errorDescription: String? {
    switch self {
    case .accessibilityNotEnabled:
      return "Accessibility permissions not enabled"
    case .invalidCommand:
      return "Invalid Vim command"
    case .executionFailed(let message):
      return "Command execution failed: \(message)"
    }
  }
}