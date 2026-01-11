import Foundation
import ApplicationServices

class NormalModeHandler: ModeHandler {
  private var commandBuffer = ""
  private let commandProcessor: VimCommandProcessor

  init(commandProcessor: VimCommandProcessor) {
    self.commandProcessor = commandProcessor
  }

  func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> VimAction? {
    commandBuffer += key
    let command = commandProcessor.parseCommand(commandBuffer)
    let count = commandProcessor.extractCount(from: commandBuffer) ?? 1

    return processCommand(command, count: count)
  }

  private func processCommand(_ command: VimCommand, count: Int) -> VimAction? {
    switch command {
    case .moveLeft, .moveRight, .moveUp, .moveDown,
         .moveWordForward, .moveWordEndForward, .moveWordBackward,
         .deleteChar, .deleteLine, .deleteToEndOfLine,
         .yankLine, .goToFirstLine, .goToLastLine:
      return .executeCommand(command, count: count)
    case .enterInsertMode:
      return .switchMode(.insert)
    case .enterInsertAfterCursor:
      return .compound([
        .simulateKeyPress(KeyboardMapping.rightArrow, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineBegin:
      return .compound([
        .simulateKeyPress(KeyboardMapping.homeKey, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineEnd:
      return .compound([
        .simulateKeyPress(KeyboardMapping.endKey, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineBelow:
      return .compound([
        .simulateKeyPress(KeyboardMapping.endKey, KeyboardMapping.cmdKey),
        .simulateKeyPress(KeyboardMapping.returnKey, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineAbove:
      return .compound([
        .simulateKeyPress(KeyboardMapping.homeKey, KeyboardMapping.cmdKey),
        .simulateKeyPress(KeyboardMapping.returnKey, 0),
        .simulateKeyPress(KeyboardMapping.upArrow, 0),
        .switchMode(.insert)
      ])
    case .enterVisualMode:
      return .switchMode(.visual)
    case .enterVisualLineMode:
      return .switchMode(.visualLine)
    case .changeChar:
      return .compound([
        .executeAction {
          for _ in 0..<count {
            KeySimulator.press(keyCode: KeyboardMapping.backspaceKey)
          }
        },
        .switchMode(.insert)
      ])
    case .changeLine, .changeToEndOfLine:
      return .compound([
        .executeCommand(command, count: count),
        .switchMode(.insert)
      ])
    case .pasteAfter:
      return .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.rightArrow)
        KeySimulator.press(keyCode: KeyboardMapping.vKey, modifiers: KeyboardMapping.cmdKey)
      }
    case .pasteBefore:
      return .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.vKey, modifiers: KeyboardMapping.cmdKey)
      }
    case .undo:
      return .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.zKey, modifiers: KeyboardMapping.cmdKey)
      }
    case .redo:
      return .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.zKey, modifiers: KeyboardMapping.cmdKey | KeyboardMapping.shiftKey)
      }
    case .exitToNormalMode:
      return nil
    case .unknown:
      if commandBuffer.count >= 2 {
        clearBuffer()
      }
      return nil
    default:
      clearBuffer()
      return nil
    }
  }

  func onEnter(from oldMode: VimMode) {
    if oldMode == .insert {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    } else if oldMode == .visual || oldMode == .visualLine {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
        KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
      }
    }
  }

  func onExit() {
    clearBuffer()
  }

  private func clearBuffer() {
    commandBuffer = ""
  }
}
