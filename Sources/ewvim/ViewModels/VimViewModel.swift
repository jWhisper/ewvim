import Foundation
import SwiftUI
import ApplicationServices

@MainActor
class VimViewModel: ObservableObject {
  @Published var mode: VimMode = .normal
  @Published var currentCommand: String = ""
  @Published var accessibilityEnabled: Bool = false

  private var state = VimState()
  private var commandProcessor: VimCommandProcessor?
  private var keyboardMonitor: KeyboardMonitor?

  init() {
    print("🚀 VimViewModel init, initial mode: \(state.mode.rawValue)")
    commandProcessor = VimCommandProcessor()
    keyboardMonitor = KeyboardMonitor { [weak self] key in
      self?.handleKeyPress(key)
    }
  }

  func requestAccessibility() {
    let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
    accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

    if accessibilityEnabled {
      startMonitoring()
    }
  }

  private func startMonitoring() {
    keyboardMonitor?.start()
    print("ewvim started monitoring keyboard")
  }

  private func handleKeyPress(_ key: String) {
    print("⌨️ handleKeyPress: key='\(key)', state.mode=\(state.mode.rawValue)")

    switch state.mode {
    case .normal:
      handleNormalMode(key)
    case .insert:
      handleInsertMode(key)
    case .visual:
      handleVisualMode(key)
    case .command:
      handleCommandMode(key)
    }
  }

  private func handleNormalMode(_ key: String) {
    print("⌨️ Normal mode handling: key='\(key)', state.mode=\(state.mode.rawValue)")

    state.commandBuffer += key
    currentCommand = state.commandBuffer

    let command = commandProcessor?.parseCommand(state.commandBuffer) ?? .unknown
    print("⌨️ Command parsed: \(command), buffer: \(state.commandBuffer)")

    switch command {
    case .moveLeft:
      executeMove(.left)
      clearCommand()
    case .moveRight:
      executeMove(.right)
      clearCommand()
    case .moveUp:
      executeMove(.up)
      clearCommand()
    case .moveDown:
      executeMove(.down)
      clearCommand()
    case .enterInsertMode:
      print("🔄 Switching to INSERT mode")
      setMode(.insert)
      clearCommand()
    case .enterVisualMode:
      setMode(.visual)
      clearCommand()
    case .enterCommandMode:
      setMode(.command)
      clearCommand()
    case .exitToNormalMode:
      clearCommand()
    case .unknown:
      print("⚠️  Unknown command, clearing buffer")
      clearCommand()
    default:
      clearCommand()
    }
  }

  private func handleInsertMode(_ key: String) {
    print("📝 INSERT mode: key='\(key)', state.mode=\(state.mode.rawValue)")

    if key == "Escape" {
      print("🔄 ESC pressed in INSERT mode → switching to NORMAL")
      setMode(.normal)
      return
    }

    print("📝 INSERT mode: ignoring non-ESC key: \(key)")
  }

  private func handleVisualMode(_ key: String) {
    if key == "Escape" {
      setMode(.normal)
    } else {
      handleNormalMode(key)
    }
  }

  private func handleCommandMode(_ key: String) {
    if key == "Escape" {
      setMode(.normal)
    } else if key == "Enter" {
      executeCommand(currentCommand)
      setMode(.normal)
    }
  }

  private func setMode(_ newMode: VimMode) {
    print("🔄 MODE CHANGE: \(state.mode.rawValue) → \(newMode.rawValue)")
    state.mode = newMode
    mode = newMode
    state.commandBuffer = ""
    currentCommand = ""
    print("🔄 Mode set, state.mode is now: \(state.mode.rawValue)")
  }

  private func clearCommand() {
    state.commandBuffer = ""
    currentCommand = ""
  }

  private func executeMove(_ direction: MoveDirection) {
    var keyCode: CGKeyCode
    var directionName: String

    switch direction {
    case .left:
      keyCode = 0x7B
      directionName = "left"
    case .right:
      keyCode = 0x7C
      directionName = "right"
    case .up:
      keyCode = 0x7E
      directionName = "up"
    case .down:
      keyCode = 0x7D
      directionName = "down"
    }

    print("🎯 Simulating \(directionName) arrow (keyCode: 0x\(String(format: "%02X", keyCode))")
    KeySimulator.press(keyCode: keyCode)
  }

  private func executeCommand(_ command: String) {
    print("Executing command: \(command)")
  }
}

enum MoveDirection {
  case left, right, up, down
}
