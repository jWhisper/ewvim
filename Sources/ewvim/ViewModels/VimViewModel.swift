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
    print("⌨️ handleKeyPress: key=[\(key)], keyCode=\(keyCode), mode=\(mode.rawValue)")

    guard let handler = currentModeHandler else { return false }

    // Normal 模式下所有按键都要拦截，即使没有定义命令
    if mode == .normal {
      if let action = handler.handleKeyPress(key, keyCode: keyCode) {
        return executeAction(action)
      }
      print("   🚫 Normal mode: undefined key, intercepted")
      return true
    }

    // 其他模式下，只有定义的按键才拦截
    guard let action = handler.handleKeyPress(key, keyCode: keyCode) else { return false }
    return executeAction(action)
  }

  private func executeAction(_ action: VimAction) -> Bool {
    print("🎯 executeAction: [\(action)]")
    switch action {
    case .switchMode(let newMode):
      setMode(newMode)
      return true
    case .simulateKeyPress(let keyCode, let modifiers):
      print("   ⌨️ Simulating key press: keyCode=\(keyCode), modifiers=\(modifiers)")
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
    print("🎯 executeWordForward: count=\(count)")
    print("   🔍 Getting text state...")
    guard let state = getCurrentTextState() else {
      print("   ❌ Failed to get text state, using fallback")
      // 降级到原有行为
      fallbackWordForward(count: count)
      return
    }
    print("   ✅ Got text: [\(state.fullText.prefix(50))...] cursor=\(state.cursorPosition)")

    var currentPos = state.cursorPosition
    for i in 0..<count {
      print("   🔍 Iteration \(i + 1)/\(count): currentPos=\(currentPos)")
      guard let target = WordAnalyzer.findNextWordStart(from: currentPos, in: state.fullText) else {
        print("   ❌ No more word start found")
        break
      }
      print("   ✅ Found word start at \(target)")
      currentPos = target
    }

    print("   🎯 Moving from \(state.cursorPosition) to \(currentPos)")
    executeMove(from: state.cursorPosition, to: currentPos)
  }

  private func executeWordEndForward(count: Int = 1) {
    print("🎯 executeWordEndForward: count=\(count)")
    print("   🔍 Getting text state...")
    guard let state = getCurrentTextState() else {
      print("   ❌ Failed to get text state, using fallback")
      // 降级到原有行为
      fallbackWordEndForward(count: count)
      return
    }
    print("   ✅ Got text: [\(state.fullText.prefix(50))...] cursor=\(state.cursorPosition)")

    var currentPos = state.cursorPosition
    for i in 0..<count {
      print("   🔍 Iteration \(i + 1)/\(count): currentPos=\(currentPos)")
      guard let target = WordAnalyzer.findCurrentOrNextWordEnd(from: currentPos, in: state.fullText) else {
        print("   ❌ No more word end found")
        break
      }
      print("   ✅ Found word end at \(target)")
      currentPos = target
    }

    print("   🎯 Moving from \(state.cursorPosition) to \(currentPos)")
    executeMove(from: state.cursorPosition, to: currentPos)
  }

  // 降级函数：无法通过 Accessibility API 获取文本时的原有行为
  private func fallbackWordForward(count: Int) {
    print("   🔄 fallbackWordForward: count=\(count)")
    KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
    for _ in 0..<count {
      KeySimulator.press(keyCode: KeyboardMapping.eKey, modifiers: KeyboardMapping.optionKey)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: KeyboardMapping.rightArrow, modifiers: KeyboardMapping.shiftKey)
    }
  }

  private func fallbackWordEndForward(count: Int) {
    print("   🔄 fallbackWordEndForward: count=\(count)")
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
    print("🎯 executeWordBackward: count=\(count)")
    print("   🔍 Getting text state...")
    guard let state = getCurrentTextState() else {
      print("   ❌ Failed to get text state, using fallback")
      // 降级到原有行为
      fallbackWordBackward(count: count)
      return
    }
    print("   ✅ Got text: [\(state.fullText.prefix(50))...] cursor=\(state.cursorPosition)")

    var currentPos = state.cursorPosition
    for i in 0..<count {
      print("   🔍 Iteration \(i + 1)/\(count): currentPos=\(currentPos)")
      guard let target = WordAnalyzer.findPreviousWordStart(from: currentPos, in: state.fullText) else {
        print("   ❌ No more word start found")
        break
      }
      print("   ✅ Found word start at \(target)")
      currentPos = target
    }

    print("   🎯 Moving from \(state.cursorPosition) to \(currentPos)")
    executeMove(from: state.cursorPosition, to: currentPos)
  }

  private struct TextState {
    let fullText: String
    let cursorPosition: Int
  }

  private func getCurrentTextState() -> TextState? {
    print("      🔍 getCurrentTextState: trying to get focused element...")
    guard let element = AccessibilityService.shared.getFocusedElement() else {
      print("      ❌ No focused element")
      return nil
    }
    print("      ✅ Got focused element")

    print("      🔍 Getting text from element...")
    guard let text = AccessibilityService.shared.getText(from: element) else {
      print("      ❌ Could not get text")
      return nil
    }
    print("      ✅ Got text, length=\(text.count)")

    print("      🔍 Getting selected range...")
    guard let range = AccessibilityService.shared.getSelectedRange(from: element) else {
      print("      ❌ Could not get selected range")
      return nil
    }
    print("      ✅ Got range: location=\(range.location), length=\(range.length)")

    print("      📦 Text at cursor: \"\(text.prefix(max(0, range.location - 3)))|\(String(text.dropFirst(range.location).prefix(10)))|\"")
    return TextState(fullText: text, cursorPosition: range.location)
  }

  private func executeMove(from: Int, to: Int) {
    let (arrowCount, direction) = MovementCalculator.calculateArrowKeysToMove(from: from, to: to)
    print("      🚀 executeMove: from=\(from), to=\(to), count=\(arrowCount), direction=\(direction)")

    switch direction {
    case .left:
      for _ in 0..<arrowCount {
        KeySimulator.press(keyCode: KeyboardMapping.leftArrow)
      }
    case .right:
      for _ in 0..<arrowCount {
        KeySimulator.press(keyCode: KeyboardMapping.rightArrow)
      }
    }

    // 不再需要恢复选择的逻辑
    // 原来的 Option+箭头移动需要保持选区，但精确箭头移动不需要
  }

  // 降级函数：无法通过 Accessibility API 获取文本时的原有行为
  private func fallbackWordBackward(count: Int) {
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
