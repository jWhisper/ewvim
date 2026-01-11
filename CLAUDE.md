# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Debug build
swift build

# Release build (optimized)
swift build --configuration release

# Run application (debug)
swift run ewvim

# Run application (release)
./.build/release/ewvim

# Clean build artifacts
swift package clean

# Run tests (when added)
swift test

# Run single test (when added)
swift test --filter TestClassName.testMethodName

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## High-Level Architecture

ewvim follows an **MVVM architecture with a service layer**, using native macOS APIs for system-wide keyboard monitoring and key simulation.

### Data Flow

```
Keyboard Event → KeyboardMonitor (CGEvent tap)
                    ↓
              VimViewModel (@MainActor)
                    ↓
           VimCommandProcessor (parse)
                    ↓
              KeySimulator (CGEvent post)
                    ↓
            Target Application
```

### Component Responsibilities

- **App.swift**: Entry point, sets `.accessory` policy (app doesn't appear in dock)
- **VimViewModel**: `@MainActor` coordinator with `@Published` properties for SwiftUI reactivity
- **VimCommandProcessor**: Parses Vim commands from command buffer string
- **KeyboardMonitor**: Global CGEvent tap that calls closure on each keypress, returns `true` to intercept/consume
- **KeySimulator**: Posts synthetic keyDown/keyUp events to system
- **AccessibilityService**: Wrapper for macOS AX APIs (currently minimal)

### Key Implementation Details

**Keyboard Interception**: The `KeyboardMonitor` callback returns `Bool` - `true` means consume/intercept the key, `false` means pass through to the target application. This is how ewvim distinguishes between Vim commands (intercepted) and typing in Insert mode (passed through).

**Mode Handling**: Each mode has a dedicated handler in `VimViewModel`:

- `handleNormalMode()`: Builds command buffer, parses, executes
- `handleInsertMode()`: Only ESC/JK switches to Normal mode; all keys pass through
- `handleVisualMode()`: Like Normal but with visual selection semantics
- `handleCommandMode()`: Buffers for `:` commands

**Command Buffer**: Accumulates keys in `state.commandBuffer`. Each new key causes re-parsing - commands like `10j` work because `parseCommand()` is called on each keystroke.

## Code Conventions Summary

- **Naming**: camelCase for functions/variables, PascalCase for types, enum cases are camelCase
- **Access Control**: Default to `private`, Singleton pattern is `static let shared = ClassName()`
- **SwiftUI**: Use `@StateObject` for ViewModels, `@Published` for reactive properties, chain modifiers
- **Closures**: Use `[weak self]` to avoid retain cycles
- **CF Types**: Use `takeRetainedValue()`/`passRetainedValue()` for CoreFoundation interoperability

## Platform-Specific Notes

**Target Platform**: macOS 13.0+

**CGEvent Tap**: Used for both monitoring (creating tap with callback) and simulation (creating events with `CGEvent(keyboardEventSource:)` and posting with `cghidEventTap`)

**Permission Requirements**: Accessibility permissions must be granted via System Settings. Check with `AXIsProcessTrustedWithOptions()`.

## Adding New Vim Commands

1. Add case to `VimCommand` enum in `Models/VimModels.swift`
2. Add parsing logic in `VimCommandProcessor.parseCommand(_:)`
3. Handle command in `VimViewModel.handleNormalMode(_:)` or appropriate mode handler
4. Implement execution using `KeySimulator.press(keyCode:)` or AX APIs

## 参考资料

https://github.com/godbout/kindaVim.blahblah
交互：https://kindavim.app/
