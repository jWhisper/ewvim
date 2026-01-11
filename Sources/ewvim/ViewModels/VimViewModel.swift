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
    state.commandBuffer += key
    currentCommand = state.commandBuffer

    let command = commandProcessor?.parseCommand(state.commandBuffer) ?? .unknown

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
      break
    default:
      clearCommand()
    }
  }

  private func handleInsertMode(_ key: String) {
    if key == "Escape" {
      setMode(.normal)
    }
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
    state.mode = newMode
    mode = newMode
    state.commandBuffer = ""
    currentCommand = ""
  }

  private func clearCommand() {
    state.commandBuffer = ""
    currentCommand = ""
  }

  private func executeMove(_ direction: MoveDirection) {
    switch direction {
    case .left:
      KeySimulator.press(keyCode: 0x7B)
    case .right:
      KeySimulator.press(keyCode: 0x7C)
    case .up:
      KeySimulator.press(keyCode: 0x7E)
    case .down:
      KeySimulator.press(keyCode: 0x7D)
    }
  }

  private func executeCommand(_ command: String) {
    print("Executing command: \(command)")
  }
}

enum MoveDirection {
  case left, right, up, down
}