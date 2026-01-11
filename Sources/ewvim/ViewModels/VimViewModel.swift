import Foundation
import SwiftUI
import ApplicationServices

@MainActor
class VimViewModel: ObservableObject {
  @Published var mode: VimMode = .insert
  @Published var currentCommand: String = ""
  @Published var accessibilityEnabled: Bool = false

  private var currentModeHandler: ModeHandler?
  private var modeHandlers: [VimMode: ModeHandler] = [:]
  private var keyboardMonitor: KeyboardMonitor?
  private let commandProcessor = VimCommandProcessor()

  init() {
    print("🚀 VimViewModel init, initial mode: \(mode.rawValue)")

    self.modeHandlers = [
      .normal: NormalModeHandler(commandProcessor: commandProcessor),
      .insert: InsertModeHandler(),
      .visual: VisualModeHandler(commandProcessor: commandProcessor),
      .visualLine: VisualModeHandler(commandProcessor: commandProcessor)
    ]

    self.currentModeHandler = modeHandlers[.insert]

    setupKeyboardMonitor()
    setupNotificationObserver()
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

  func cleanup() {
    print("🧹 VimViewModel: cleaning up...")
    keyboardMonitor?.willTerminate()
    keyboardMonitor?.stop()
    keyboardMonitor = nil
    print("🧹 VimViewModel: cleanup complete")

    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }

  private func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> Bool {
    print("⌨️ handleKeyPress: key='\(key)', keyCode=\(keyCode), mode=\(mode.rawValue)")

    if keyCode == KeyboardMapping.escKey {
      if mode != .insert && mode != .normal {
        setMode(.normal)
        return true
      }
    }

    guard let handler = currentModeHandler else { return false }
    guard let action = handler.handleKeyPress(key, keyCode: keyCode) else { return false }

    return executeAction(action)
  }

  private func executeAction(_ action: VimAction) -> Bool {
    switch action {
    case .switchMode(let newMode):
      setMode(newMode)
      return true
    case .simulateKeyPress(let keyCode, let modifiers):
      KeySimulator.press(keyCode: keyCode, modifiers: modifiers)
      return true
    case .executeCommand(let command, let count):
      executeCommand(command, count: count)
      return true
    case .executeAction(let closure):
      closure()
      return true
    case .compound(let actions):
      for action in actions {
        _ = executeAction(action)
      }
      return true
    }
  }

  private func executeCommand(_ command: VimCommand, count: Int) {
    switch command {
    case .moveLeft:
      executeMoveLeft(count: count)
    case .moveRight:
      executeMoveRight(count: count)
    case .moveUp:
      executeMoveUp(count: count)
    case .moveDown:
      executeMoveDown(count: count)
    case .moveWordForward:
      executeWordForward(count: count)
    case .moveWordEndForward:
      executeWordEndForward(count: count)
    case .moveWordBackward:
      executeWordBackward(count: count)
    case .deleteChar:
      for _ in 0..<count {
        KeySimulator.press(keyCode: KeyboardMapping.backspaceKey, modifiers: KeyboardMapping.controlKey)
      }
    case .deleteLine:
      for _ in 0..<count {
        KeySimulator.press(keyCode: KeyboardMapping.homeKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.endKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.backspaceKey)
      }
    case .deleteToEndOfLine:
      KeySimulator.press(keyCode: KeyboardMapping.endKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
      KeySimulator.press(keyCode: KeyboardMapping.backspaceKey)
    case .changeLine:
      for _ in 0..<count {
        KeySimulator.press(keyCode: KeyboardMapping.homeKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.endKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.backspaceKey)
      }
    case .changeToEndOfLine:
      KeySimulator.press(keyCode: KeyboardMapping.endKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
      KeySimulator.press(keyCode: KeyboardMapping.backspaceKey)
    case .yankLine:
      for _ in 0..<count {
        KeySimulator.press(keyCode: KeyboardMapping.homeKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.endKey, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.cKey, modifiers: KeyboardMapping.cmdKey)
        KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
        KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
      }
    case .goToFirstLine:
      KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
      KeySimulator.press(keyCode: KeyboardMapping.upArrow, modifiers: KeyboardMapping.cmdKey)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
        KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
      }
    case .goToLastLine:
      KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
      KeySimulator.press(keyCode: KeyboardMapping.downArrow, modifiers: KeyboardMapping.cmdKey)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
        KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
      }
    default:
      break
    }
  }

  private func executeMoveLeft(count: Int) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func executeMoveRight(count: Int) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func executeMoveUp(count: Int) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.upArrow)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func executeMoveDown(count: Int) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.downArrow)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func executeWordForward(count: Int = 1) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.eKey, modifiers: KeyboardMapping.optionKey)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func executeWordEndForward(count: Int = 1) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.eKey, modifiers: KeyboardMapping.optionKey)
      KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func executeWordBackward(count: Int = 1) {
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.leftArrow, modifiers: KeyboardMapping.optionKey)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  func setMode(_ newMode: VimMode) {
    print("🔄 MODE CHANGE: \(mode.rawValue) → \(newMode.rawValue)")
    let oldMode = mode

    currentModeHandler?.onExit()

    mode = newMode
    currentModeHandler = modeHandlers[newMode]
    currentCommand = ""

    currentModeHandler?.onEnter(from: oldMode)

    print("🔄 Mode set, mode is now: \(mode.rawValue)")
  }

  private func setupKeyboardMonitor() {
    keyboardMonitor = KeyboardMonitor { [weak self] key, keyCode in
      return self?.handleKeyPress(key, keyCode: keyCode) ?? false
    }

    keyboardMonitor?.onQuit = { [weak self] in
      Task { @MainActor in
        self?.cleanup()
      }
    }
  }

  private func setupNotificationObserver() {
    NotificationCenter.default.addObserver(
      forName: Notification.Name("appWillTerminate"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor in
        self?.cleanup()
      }
    }
  }
}
