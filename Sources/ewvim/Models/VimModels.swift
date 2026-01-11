import Foundation

enum VimMode: String {
  case normal = "normal"
  case insert = "insert"
  case visual = "visual"
  case command = "command"
}

struct VimState {
  var mode: VimMode
  var commandBuffer: String
  var count: Int
  var register: Character?
  var registerValue: String?

  init() {
    self.mode = .normal
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
  case enterInsertMode
  case enterVisualMode
  case enterCommandMode
  case exitToNormalMode
  case delete
  case change
  case yank
  case paste
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