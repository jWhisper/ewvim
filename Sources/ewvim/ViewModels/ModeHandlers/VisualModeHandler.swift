import Foundation
import ApplicationServices

class VisualModeHandler: ModeHandler {
  private let commandProcessor: VimCommandProcessor
  private var commandBuffer = ""

  init(commandProcessor: VimCommandProcessor) {
    self.commandProcessor = commandProcessor
  }

  func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> VimAction? {
    // ESC 切换回正常模式
    if keyCode == KeyboardMapping.escKey {
      return .switchMode(.normal)
    }

    let shiftModifier: UInt64 = KeyboardMapping.shiftKey

    switch key {
    case "h":
      return .simulateKeyPress(KeyboardMapping.leftArrow, shiftModifier)
    case "j":
      return .simulateKeyPress(KeyboardMapping.downArrow, shiftModifier)
    case "k":
      return .simulateKeyPress(KeyboardMapping.upArrow, shiftModifier)
    case "l":
      return .simulateKeyPress(KeyboardMapping.rightArrow, shiftModifier)
    case "g":
      commandBuffer += key
      let command = commandProcessor.parseCommand(commandBuffer)
      if command == .goToFirstLine {
        return .simulateKeyPress(KeyboardMapping.upArrow, KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
      }
      return nil
    case "G":
      return .simulateKeyPress(KeyboardMapping.downArrow, KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
    default:
      commandBuffer += key
      let command = commandProcessor.parseCommand(commandBuffer)
      if command != .unknown {
        return .switchMode(.normal)
      }
      return nil
    }
  }

  func onEnter(from oldMode: VimMode) {}

  func onExit() {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
  }
}
