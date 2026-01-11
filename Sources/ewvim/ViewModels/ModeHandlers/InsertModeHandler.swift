import Foundation
import ApplicationServices

class InsertModeHandler: ModeHandler {
  private lazy var sequenceDetector: KeySequenceDetector = {
    KeySequenceDetector(configs: [
      KeySequenceConfig(
        sequence: "jk",
        action: { [weak self] in
          self?.exitToNormal()
        },
        timeout: 0.14
      )
    ])
  }()

  func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> VimAction? {
    if key == "ESC" {
      sequenceDetector.cancel()
      return .switchMode(.normal)
    }

    let result = sequenceDetector.onKey(key, keyCode: keyCode)

    switch result {
    case .waiting:
      return nil
    case .matched:
      return nil
    case .timeout(let sendKey, _):
      return sendKey ? nil : nil
    case .mismatched:
      return nil
    }
  }

  func onEnter(from oldMode: VimMode) {
    if oldMode == .normal {
      KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
      self?.sequenceDetector.cancel()
    }
  }

  func onExit() {
    sequenceDetector.cancel()
  }

  private func exitToNormal() {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
  }
}
