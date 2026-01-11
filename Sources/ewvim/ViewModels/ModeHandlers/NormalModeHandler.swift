import Foundation
import ApplicationServices

class NormalModeHandler: ModeHandler {
  private var commandBuffer = ""
  private let commandProcessor: VimCommandProcessor

  init(commandProcessor: VimCommandProcessor) {
    self.commandProcessor = commandProcessor
  }

  func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> VimAction? {
    print("📝 NormalModeHandler: key=[\(key)], keyCode=\(keyCode)")
    commandBuffer += key
    let command = commandProcessor.parseCommand(commandBuffer)
    let count = commandProcessor.extractCount(from: commandBuffer) ?? 1

    print("   📦 commandBuffer=[\(commandBuffer)], parsed=\(command), count=\(count)")
    let action = processCommand(command, count: count)
    // 清空缓冲区，因为命令已经处理
    if action != nil {
      clearBuffer()
    }
    return action
  }

  private func processCommand(_ command: VimCommand, count: Int) -> VimAction? {
    print("   🔧 processCommand: \(command), count=\(count)")
    let action: VimAction?
    switch command {
    case .moveLeft, .moveRight, .moveUp, .moveDown,
         .moveWordForward, .moveWordEndForward, .moveWordBackward,
         .deleteChar, .deleteLine, .deleteToEndOfLine,
         .yankLine, .goToFirstLine, .goToLastLine:
      action = .executeCommand(command, count: count)
    case .enterInsertMode:
      action = .switchMode(.insert)
    case .enterInsertAfterCursor:
      action = .compound([
        .simulateKeyPress(KeyboardMapping.rightArrow, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineBegin:
      action = .compound([
        .simulateKeyPress(KeyboardMapping.homeKey, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineEnd:
      action = .compound([
        .simulateKeyPress(KeyboardMapping.endKey, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineBelow:
      action = .compound([
        .simulateKeyPress(KeyboardMapping.endKey, KeyboardMapping.cmdKey),
        .simulateKeyPress(KeyboardMapping.returnKey, 0),
        .switchMode(.insert)
      ])
    case .enterInsertLineAbove:
      action = .compound([
        .simulateKeyPress(KeyboardMapping.homeKey, KeyboardMapping.cmdKey),
        .simulateKeyPress(KeyboardMapping.returnKey, 0),
        .simulateKeyPress(KeyboardMapping.upArrow, 0),
        .switchMode(.insert)
      ])
    case .enterVisualMode:
      action = .switchMode(.visual)
    case .enterVisualLineMode:
      action = .switchMode(.visualLine)
    case .changeChar:
      action = .compound([
        .executeAction {
          for _ in 0..<count {
            KeySimulator.press(keyCode: KeyboardMapping.backspaceKey)
          }
        },
        .switchMode(.insert)
      ])
    case .changeLine, .changeToEndOfLine:
      action = .compound([
        .executeCommand(command, count: count),
        .switchMode(.insert)
      ])
    case .pasteAfter:
      action = .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.rightArrow)
        KeySimulator.press(keyCode: KeyboardMapping.vKey, modifiers: KeyboardMapping.cmdKey)
      }
    case .pasteBefore:
      action = .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.vKey, modifiers: KeyboardMapping.cmdKey)
      }
    case .undo:
      action = .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.zKey, modifiers: KeyboardMapping.cmdKey)
      }
    case .redo:
      action = .executeAction {
        KeySimulator.press(keyCode: KeyboardMapping.zKey, modifiers: KeyboardMapping.cmdKey | KeyboardMapping.shiftKey)
      }
    case .exitToNormalMode:
      action = nil
    case .unknown:
      if commandBuffer.count >= 2 {
        clearBuffer()
      }
      action = nil
    default:
      clearBuffer()
      action = nil
    }
    print("   ✅ returning action: \(String(describing: action))")
    return action
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
