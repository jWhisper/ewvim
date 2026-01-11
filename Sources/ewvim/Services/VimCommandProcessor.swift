import Foundation

class VimCommandProcessor {
  func parseCommand(_ buffer: String) -> VimCommand {
    let command = buffer.lowercased()

    switch command {
    case "h":
      return .moveLeft
    case "j":
      return .moveDown
    case "k":
      return .moveUp
    case "l":
      return .moveRight
    case "i":
      return .enterInsertMode
    case "v":
      return .enterVisualMode
    case ":":
      return .enterCommandMode
    case "Escape":
      return .exitToNormalMode
    default:
      if command.hasSuffix("h") {
        return .moveLeft
      } else if command.hasSuffix("j") {
        return .moveDown
      } else if command.hasSuffix("k") {
        return .moveUp
      } else if command.hasSuffix("l") {
        return .moveRight
      }
      return .unknown
    }
  }

  func extractCount(from command: String) -> Int? {
    let numericPrefix = command.prefix(while: { $0.isNumber })
    return Int(numericPrefix)
  }
}