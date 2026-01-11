import Foundation
import SwiftUI
import ApplicationServices

@MainActor
class VimViewModel: ObservableObject {
  @Published var mode: VimMode = .insert
  @Published var currentCommand: String = ""
  @Published var accessibilityEnabled: Bool = false

  private var state = VimState()
  private var commandProcessor: VimCommandProcessor?
  private var keyboardMonitor: KeyboardMonitor?
  private var insertSequenceDetector: KeySequenceDetector?

  init() {
    print("🚀 VimViewModel init, initial mode: \(state.mode.rawValue)")
    commandProcessor = VimCommandProcessor()

    // Setup KeySequenceDetector for Insert mode (jk to exit)
    insertSequenceDetector = KeySequenceDetector(configs: [
      KeySequenceConfig(
        sequence: "jk",
        action: { [weak self] in self?.setMode(.normal) },
        timeout: 0.14
      )
    ])

    keyboardMonitor = KeyboardMonitor { [weak self] key, keyCode in
      return self?.handleKeyPress(key, keyCode: keyCode) ?? false
    }

    keyboardMonitor?.onQuit = { [weak self] in
      Task { @MainActor in
        self?.cleanup()
      }
    }

    // Setup notification observer for app termination
    NotificationCenter.default.addObserver(
      forName: Notification.Name("appWillTerminate"),
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.cleanup()
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

  func cleanup() {
    print("🧹 VimViewModel: cleaning up...")
    keyboardMonitor?.willTerminate()
    keyboardMonitor?.stop()
    keyboardMonitor = nil
    print("🧹 VimViewModel: cleanup complete")

    // Terminate NSApp to fully quit the application
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }

  private func handleKeyPress(_ key: String, keyCode: CGKeyCode) -> Bool {
    print("⌨️ handleKeyPress: key='\(key)', keyCode=\(keyCode), state.mode=\(state.mode.rawValue)")

    // ESC key (keyCode 0x35) always exits to Normal mode from any mode except Insert
    if keyCode == KeyboardMapping.escKey {
      if state.mode != .insert && state.mode != .normal {
        setMode(.normal)
        return true
      }
    }

    switch state.mode {
    case .normal:
      return handleNormalMode(key)
    case .insert:
      return handleInsertMode(key, keyCode: keyCode)
    case .visual, .visualLine:
      return handleVisualMode(key, keyCode: keyCode)
    }
  }

  private func handleNormalMode(_ key: String) -> Bool {
    print("⌨️ Normal mode handling: key='\(key)', state.mode=\(state.mode.rawValue)")

    state.commandBuffer += key
    currentCommand = state.commandBuffer

    let command = commandProcessor?.parseCommand(state.commandBuffer) ?? .unknown
    print("⌨️ Command parsed: \(command), buffer: \(state.commandBuffer)")

    // Extract count before switching
    let count = commandProcessor?.extractCount(from: state.commandBuffer) ?? 1

    switch command {
    // Motion commands
    case .moveLeft:
      executeMove(.left, count: count)
      clearCommand()
      return true
    case .moveRight:
      executeMove(.right, count: count)
      clearCommand()
      return true
    case .moveUp:
      executeMove(.up, count: count)
      clearCommand()
      return true
    case .moveDown:
      executeMove(.down, count: count)
      clearCommand()
      return true
    case .moveWordForward:
      executeWordForward(count: count)
      clearCommand()
      return true
    case .moveWordEndForward:
      executeWordEndForward(count: count)
      clearCommand()
      return true
    case .moveWordBackward:
      executeWordBackward(count: count)
      clearCommand()
      return true

    // Insert mode commands
    case .enterInsertMode:
      setMode(.insert)
      clearCommand()
      return true
    case .enterInsertAfterCursor:
      executeInsertAfterCursor()
      setMode(.insert)
      clearCommand()
      return true
    case .enterInsertLineBegin:
      executeInsertLineBegin()
      setMode(.insert)
      clearCommand()
      return true
    case .enterInsertLineEnd:
      executeInsertLineEnd()
      setMode(.insert)
      clearCommand()
      return true
    case .enterInsertLineBelow:
      executeInsertLineBelow()
      setMode(.insert)
      clearCommand()
      return true
    case .enterInsertLineAbove:
      executeInsertLineAbove()
      setMode(.insert)
      clearCommand()
      return true

    // Visual mode
    case .enterVisualMode:
      setMode(.visual)
      clearCommand()
      return true
    case .enterVisualLineMode:
      setMode(.visualLine)
      clearCommand()
      return true

    // Delete commands
    case .deleteChar:
      executeDeleteChar(count: count)
      clearCommand()
      return true
    case .deleteLine:
      executeDeleteLine(count: count)
      clearCommand()
      return true
    case .deleteToEndOfLine:
      executeDeleteToEndOfLine()
      clearCommand()
      return true

    // Change commands
    case .changeChar:
      executeChangeChar(count: count)
      setMode(.insert)
      clearCommand()
      return true
    case .changeLine:
      executeDeleteLine(count: count)
      setMode(.insert)
      clearCommand()
      return true
    case .changeToEndOfLine:
      executeDeleteToEndOfLine()
      setMode(.insert)
      clearCommand()
      return true

    // Yank commands
    case .yankLine:
      executeYankLine(count: count)
      clearCommand()
      return true

    // Paste commands
    case .pasteAfter:
      executePasteAfter()
      clearCommand()
      return true
    case .pasteBefore:
      executePasteBefore()
      clearCommand()
      return true

    // Undo/Redo
    case .undo:
      executeUndo()
      clearCommand()
      return true
    case .redo:
      executeRedo()
      clearCommand()
      return true

    // Line navigation
    case .goToFirstLine:
      print("🎯 VimViewModel: handling .goToFirstLine")
      executeGoToLine(.first)
      clearCommand()
      return true
    case .goToLastLine:
      print("🎯 VimViewModel: handling .goToLastLine")
      executeGoToLine(.last)
      clearCommand()
      return true

    case .exitToNormalMode:
      clearCommand()
      return true
    case .unknown:
      // Check if we're building a multi-char command (like first 'g' of 'gg')
      // Don't clear yet, waiting for next key
      if state.commandBuffer.count >= 2 {
        clearCommand()
      }
      // Intercept all undefined commands in Normal mode
      return true
    default:
      clearCommand()
      return false
    }
  }

  private func handleInsertMode(_ key: String, keyCode: CGKeyCode) -> Bool {
    print("📝 INSERT mode: key='\(key)', keyCode=\(keyCode), state.mode=\(state.mode.rawValue)")

    if key == "ESC" {
      print("🔄 ESC pressed in INSERT mode → switching to NORMAL")
      insertSequenceDetector?.cancel()
      setMode(.normal)
      return true
    }

    guard let detector = insertSequenceDetector else {
      return false
    }

    let result = detector.onKey(key, keyCode: keyCode)

    switch result {
    case .waiting:
      print("⏸️ Waiting for key sequence...")
      return true  // Intercept, waiting for more keys
    case .matched:
      print("✅ Key sequence matched")
      return true
    case .timeout(let sendKey, _):
      return sendKey
    case .mismatched:
      // Keys don't form a sequence, pass them through
      return false
    }
  }

  private func handleVisualMode(_ key: String, keyCode: CGKeyCode) -> Bool {
    print("👁️ VISUAL mode: key='\(key)', keyCode=\(keyCode), state.mode=\(state.mode.rawValue)")

    // ESC is already handled in handleKeyPress via keyCode check

    // In visual mode, use Shift + Arrow for selection
    let shiftModifier: UInt64 = 0x20000  // Shift key modifier

    switch key {
    case "h":
      // Shift + LeftArrow for selection
      KeySimulator.press(keyCode: 0x7B, modifiers: shiftModifier)
      return true
    case "j":
      // Shift + DownArrow for selection
      KeySimulator.press(keyCode: 0x7D, modifiers: shiftModifier)
      return true
    case "k":
      // Shift + UpArrow for selection
      KeySimulator.press(keyCode: 0x7E, modifiers: shiftModifier)
      return true
    case "l":
      // Shift + RightArrow for selection
      KeySimulator.press(keyCode: 0x7C, modifiers: shiftModifier)
      return true
    case "g":
      // Wait for second 'g'
      state.commandBuffer += key
      let command = commandProcessor?.parseCommand(state.commandBuffer) ?? .unknown
      if command == .goToFirstLine {
        // Cmd + Shift + UpArrow to select to first line
        KeySimulator.press(keyCode: 0x7E, modifiers: 0x120000)  // Cmd + Shift + Up
        clearCommand()
        return true
      }
      return false
    case "G":
      // Cmd + Shift + DownArrow to select to last line
      KeySimulator.press(keyCode: 0x7D, modifiers: 0x120000)  // Cmd + Shift + Down
      return true
    default:
      state.commandBuffer += key
      let command = commandProcessor?.parseCommand(state.commandBuffer) ?? .unknown
      clearCommand()
      return command != .unknown
    }
  }

  private func setMode(_ newMode: VimMode) {
    print("🔄 MODE CHANGE: \(state.mode.rawValue) → \(newMode.rawValue)")
    let oldMode = state.mode

    // When entering Insert mode, clear any selection first
    if newMode == .insert && oldMode == .normal {
      // Clear selection by pressing Left arrow to cancel any active selection
      KeySimulator.press(keyCode: 0x7B)
      // Small delay before canceling sequence to ensure selection is cleared
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
        self?.insertSequenceDetector?.cancel()
      }
    } else {
      // Cancel any pending sequence detection when mode changes
      insertSequenceDetector?.cancel()
    }

    // When exiting visual mode, clear selection
    if (oldMode == .visual || oldMode == .visualLine) && newMode == .normal {
      // Clear selection by pressing an arrow key
      KeySimulator.press(keyCode: 0x7B)  // Left arrow
    }

    state.mode = newMode
    mode = newMode
    state.commandBuffer = ""
    currentCommand = ""

    // When entering Normal mode, select the character under cursor for visual feedback
    // Do this AFTER mode is actually set, with a small delay
    if newMode == .normal && oldMode != .normal {
      // Small delay to ensure mode switch is processed
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
        self?.selectCurrentChar()
      }
    }

    print("🔄 Mode set, state.mode is now: \(state.mode.rawValue)")
  }

  /// Select the character under cursor for visual feedback (like Vim block cursor)
  /// Strategy: Shift+Right to select the character to the right of cursor
  /// This stays on the same line - Shift+Right at line end does nothing (like Vim)
  private func selectCurrentChar() {
    print("🎯 Selecting character for Normal mode visual feedback")
    let shiftKey: UInt64 = 0x20000

    // Shift+Right selects the character to the right
    // At line end, Shift+Right does nothing (cursor stays), which is correct Vim behavior
    KeySimulator.press(keyCode: 0x7C, modifiers: shiftKey)            // Shift + Right arrow (select)
  }

  private func clearCommand() {
    state.commandBuffer = ""
    currentCommand = ""
  }

  private func executeMove(_ direction: MoveDirection, count: Int = 1) {
    switch direction {
    case .left:
      print("🎯 Moving left \(count) times")
      executeMoveLeft(count: count)
    case .right:
      print("🎯 Moving right \(count) times")
      executeMoveRight(count: count)
    case .up:
      print("🎯 Moving up \(count) times")
      executeMoveUp(count: count)
    case .down:
      print("🎯 Moving down \(count) times")
      executeMoveDown(count: count)
    }
  }

  /// Move left: cancel selection first, then move, then reselect
  private func executeMoveLeft(count: Int) {
    // Cancel selection (shift+right selects from left to right, so left returns to original position)
    // Press Left once to cancel selection (cursor stays at original position)
    KeySimulator.press(keyCode: 0x7B)

    // Now move left count times
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x7B)
    }

    // Reselect - Shift+Right selects the character to the right
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: 0x7C, modifiers: 0x20000)
    }
  }

  /// Move right: cancel selection, move, then reselect at new position
  private func executeMoveRight(count: Int) {
    // Cancel selection (shift+right selects 1 character to the right)
    // Press Left once to cancel - cursor is now at the original position
    KeySimulator.press(keyCode: 0x7B)

    // Now move right count times
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x7C)
    }

    // Reselect - Shift+Right at the new position
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: 0x7C, modifiers: 0x20000)
    }
  }

  /// Move up: cancel selection, move up, then reselect
  private func executeMoveUp(count: Int) {
    // Cancel selection - press Left once
    KeySimulator.press(keyCode: 0x7B)

    // Move up count times
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x7E)
    }

    // Reselect - Shift+Right at the new position
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) { [weak self] in
      self?.selectCurrentChar()
    }
  }

  /// Move down: cancel selection, move down, then reselect
  private func executeMoveDown(count: Int) {
    // Cancel selection - press Left once
    KeySimulator.press(keyCode: 0x7B)

    // Move down count times
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x7D)
    }

    // Reselect - Shift+Right at the new position
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) { [weak self] in
      self?.selectCurrentChar()
    }
  }

  // Word movements
  private func executeWordForward(count: Int = 1) {
    print("🎯 Moving forward \(count) word(s)")
    // Cancel selection - press Left once
    KeySimulator.press(keyCode: 0x7B)
    // Move through words
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x0D, modifiers: KeyboardMapping.optionKey)  // Option + Right
    }
    // Reselect
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: 0x7C, modifiers: 0x20000)
    }
  }

  private func executeWordEndForward(count: Int = 1) {
    print("🎯 Moving to word end \(count) time(s)")
    // Cancel selection - press Left once
    KeySimulator.press(keyCode: 0x7B)
    // Move to word end
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x0D, modifiers: KeyboardMapping.optionKey)  // Option + Right
      KeySimulator.press(keyCode: 0x7B)  // Left to move back one char to end of word
    }
    // Reselect
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: 0x7C, modifiers: 0x20000)
    }
  }

  private func executeWordBackward(count: Int = 1) {
    print("🎯 Moving backward \(count) word(s)")
    // Cancel selection - press Left once
    KeySimulator.press(keyCode: 0x7B)
    // Move through words
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x7B, modifiers: KeyboardMapping.optionKey)  // Option + Left
    }
    // Reselect
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
      KeySimulator.press(keyCode: 0x7C, modifiers: 0x20000)
    }
  }

  // Insert mode helper functions
  private func executeInsertAfterCursor() {
    print("🎯 Moving cursor right before insert")
    KeySimulator.press(keyCode: 0x7C)  // Right arrow
  }

  private func executeInsertLineBegin() {
    print("🎯 Moving to beginning of line before insert")
    KeySimulator.press(keyCode: 0x74)  // Home (Cmd + Left would also work)
  }

  private func executeInsertLineEnd() {
    print("🎯 Moving to end of line before insert")
    KeySimulator.press(keyCode: 0x75)  // End (Cmd + Right would also work)
  }

  private func executeInsertLineBelow() {
    print("🎯 Opening new line below")
    // First move to end of line, then press Enter
    KeySimulator.press(keyCode: 0x75, modifiers: KeyboardMapping.cmdKey)  // Cmd + Right (End)
    KeySimulator.press(keyCode: 0x24)  // Enter
  }

  private func executeInsertLineAbove() {
    print("🎯 Opening new line above")
    // Move to start of line, press Enter, move up
    KeySimulator.press(keyCode: 0x74, modifiers: KeyboardMapping.cmdKey)  // Cmd + Left (Home)
    KeySimulator.press(keyCode: 0x24)  // Enter
    KeySimulator.press(keyCode: 0x7E)  // Up arrow
  }

  // Delete commands
  private func executeDeleteChar(count: Int = 1) {
    print("🗑️ Deleting \(count) character(s)")
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x33, modifiers: KeyboardMapping.controlKey)  // Ctrl + D (delete forward)
    }
  }

  private func executeDeleteLine(count: Int = 1) {
    print("🗑️ Deleting \(count) line(s)")
    for _ in 0..<count {
      // Shift + Cmd +Left/Right for line selection, then delete
      KeySimulator.press(keyCode: 0x74, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)  // Shift + Cmd + Left
      KeySimulator.press(keyCode: 0x75, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)  // Shift + Cmd + Right
      KeySimulator.press(keyCode: 0x33)  // Backspace (delete)
    }
  }

  private func executeDeleteToEndOfLine() {
    print("🗑️ Deleting to end of line")
    // Cmd + Shift + Right to select to end of line, then delete
    KeySimulator.press(keyCode: 0x75, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)  // Shift + Cmd + Right
    KeySimulator.press(keyCode: 0x33)  // Backspace
  }

  // Change commands - delete and enter insert mode
  private func executeChangeChar(count: Int = 1) {
    print("✏️ Changing \(count) character(s)")
    for _ in 0..<count {
      KeySimulator.press(keyCode: 0x33)  // Backspace
    }
  }

  // Yank commands
  private func executeYankLine(count: Int = 1) {
    print("📋 Yanking \(count) line(s)")
    for _ in 0..<count {
      // Select line and copy
      KeySimulator.press(keyCode: 0x74, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)  // Shift + Cmd + Left
      KeySimulator.press(keyCode: 0x75, modifiers: KeyboardMapping.shiftKey | KeyboardMapping.cmdKey)  // Shift + Cmd + Right
      KeySimulator.press(keyCode: 0x08, modifiers: KeyboardMapping.cmdKey)  // Cmd + C (copy)
      // Deselect
      KeySimulator.press(keyCode: 0x7B)  // Left arrow
      KeySimulator.press(keyCode: 0x7B)  // Left arrow to move away from selection
    }
  }

  // Paste commands
  private func executePasteAfter() {
    print("📋 Pasting after cursor")
    KeySimulator.press(keyCode: 0x7C)  // Right arrow (move right first)
    KeySimulator.press(keyCode: 0x09, modifiers: KeyboardMapping.cmdKey)  // Cmd + V (paste)
  }

  private func executePasteBefore() {
    print("📋 Pasting before cursor")
    KeySimulator.press(keyCode: 0x09, modifiers: KeyboardMapping.cmdKey)  // Cmd + V (paste)
  }

  // Undo/Redo
  private func executeUndo() {
    print("↩️ Undo")
    KeySimulator.press(keyCode: 0x1A, modifiers: KeyboardMapping.cmdKey)  // Cmd + Z
  }

  private func executeRedo() {
    print("↪️ Redo")
    KeySimulator.press(keyCode: 0x1A, modifiers: KeyboardMapping.cmdKey | KeyboardMapping.shiftKey)  // Cmd + Shift + Z
  }

  private func executeGoToLine(_ position: GoToLinePosition) {
    print("🎯 executeGoToLine: position=\(position)")

    // Cancel selection - press Left once
    KeySimulator.press(keyCode: 0x7B)

    // Home (first line) key combination: Cmd + UpArrow
    // End (last line) key combination: Cmd + DownArrow
    switch position {
    case .first:
      // Cmd + UpArrow
      let keyCode: CGKeyCode = 0x7E
      let modifiers: UInt64 = 0x100000
      print("🎯 executeGoToLine: calling press with keyCode=0x\(String(format: "%02X", keyCode)), modifiers=0x\(String(format: "%06X", modifiers)) (Cmd + Up)")
      KeySimulator.press(keyCode: keyCode, modifiers: modifiers)  // Cmd + Up
    case .last:
      // Cmd + DownArrow
      let keyCode: CGKeyCode = 0x7D
      let modifiers: UInt64 = 0x100000
      print("🎯 executeGoToLine: calling press with keyCode=0x\(String(format: "%02X", keyCode)), modifiers=0x\(String(format: "%06X", modifiers)) (Cmd + Down)")
      KeySimulator.press(keyCode: keyCode, modifiers: modifiers)  // Cmd + Down
    }

    // Reselect
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) { [weak self] in
      self?.selectCurrentChar()
    }

    print("🎯 executeGoToLine: done")
  }
}

enum MoveDirection {
  case left, right, up, down
}

enum GoToLinePosition {
  case first
  case last
}
