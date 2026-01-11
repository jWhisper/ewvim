# ewvim Agent Guidelines

## Project Overview
ewvim is a native macOS application built with Swift and SwiftUI that provides Vim-like navigation across all applications. Uses pure Swift with no Electron/JavaScript dependencies.

## Build Commands

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

# Run all tests (when added)
swift test

# Run single test (when added)
swift test --filter TestClassName.testMethodName

# Generate Xcode project (optional)
swift package generate-xcodeproj
```

## Project Structure
```
Sources/ewvim/
├── App.swift                  # App entry point (@main)
├── Models/VimModels.swift    # Data models/enums
├── Views/ContentView.swift    # SwiftUI views
├── ViewModels/VimViewModel.swift  # State management (@MainActor)
└── Services/                # Business logic
    ├── VimCommandProcessor.swift  # Command parsing
    ├── KeyboardMonitor.swift      # Global keyboard hooks
    ├── KeySimulator.swift        # Key simulation
    └── AccessibilityService.swift # macOS Accessibility API
```

## Code Style Guidelines

### Imports
- Standard library imports first: `import Foundation`, `import SwiftUI`
- Framework imports next: `import ApplicationServices`, `import Carbon`
- No unused imports
- Alphabetically order within groups

### Naming Conventions
- **Classes**: PascalCase - `class VimViewModel`, `class KeySimulator`
- **Structs**: PascalCase - `struct ContentView`, `struct VimState`
- **Enums**: PascalCase - `enum VimMode`, `enum VimCommand`
- **Enum cases**: camelCase - `case moveLeft`, `case normal`
- **Functions/Methods**: camelCase - `func parseCommand()`, `func handleKeyPress()`
- **Variables/Properties**: camelCase - `let commandBuffer`, `var currentCommand`
- **Constants**: camelCase or dictionary keys - `let keyMap: [Character: CGKeyCode]`
- **Private members**: Use `private` by default, expose only what's needed
- **Singleton**: `static let shared = ClassName()`

### Type Annotations
- Always annotate function signatures: `func parseCommand(_ buffer: String) -> VimCommand`
- Use explicit types in properties when clarity needed
- Optional types: `String?`, `Int?` (not `Optional<String>`)
- Use type inference for local variables when type is obvious

### Access Control
- Default to `private` for implementation details
- Use `private func` for internal methods
- Use `fileprivate` only when necessary
- Avoid `public` - app is standalone executable
- Use `@Published` for ViewModel properties that need SwiftUI updates

### SwiftUI Patterns
- Use `@StateObject` for ViewModel in views
- Use `@State` for local view state
- Use `@MainActor` for ViewModels that interact with UI
- Chain modifiers: `.padding().background(Color.black).cornerRadius(6)`
- Extract reusable views as separate structs
- Add previews with `#if DEBUG` wrapper

### Memory Management
- Use `[weak self]` in closure captures
- Handle CF types with `takeRetainedValue()`/`passRetainedValue()`
- Call `stop()` methods to clean up resources
- Use `Unmanaged` for CF interoperability

### Error Handling
- Conform to `Error` and `LocalizedError` protocols
- Use enum for error cases
- Provide `errorDescription` computed property
- Print errors to console
- Don't crash on errors - log and continue

### Formatting
- 2-space indentation (or tabs, consistent per file)
- Spaces around operators: `let result = value + 1`
- No trailing whitespace
- Opening braces on same line: `if condition {`
- One blank line between functions
- Compact SwiftUI code, no excessive blank lines

### Code Organization
- Group related functions together (public first, then private)
- Order: properties → init → public methods → private methods → computed properties
- Use `// MARK:` comments to section large files
- Keep views focused and single-responsibility
- Extract complex logic into Services layer

### Swift Concurrency
- Use `@MainActor` for ViewModels updating UI
- Use `DispatchQueue.main.async` when bridging to main thread
- Use `Thread.sleep(forTimeInterval:)` for small delays only
- Avoid blocking the main thread

### Platform-Specific Notes
- Target macOS 13.0+ in Package.swift
- Use CGEvent for low-level key simulation
- Use AX APIs for accessibility
- Key codes are hex: `0x7B` for left arrow
- Use CF types carefully: CFDictionary, CFString, CFMachPort

### Testing (when added)
- Use XCTest framework
- Follow naming: `class VimCommandProcessorTests: XCTestCase`
- Test name format: `func testParseCommandReturnsCorrectVimCommand()`
- Run single test: `swift test --filter VimCommandProcessorTests.testMethodName`
- Arrange-Act-Assert pattern
- Mock dependencies using protocols

### Common Patterns

**Command Parsing**: Switch on lowercased string, return enum cases
**Keyboard Monitoring**: CGEvent tap creation with callback closure
**Key Simulation**: Create keyDown/keyUp events, post to cghidEventTap
**State Management**: Update private state, then @Published property
**Mode Switching**: Clear command buffer when changing modes

### What NOT to Do
- Don't add comments unless explaining "why", not "what"
- Don't use force unwrap `!` unless absolutely safe
- Don't use `try!` in production code
- Don't leave TODO comments - implement or file issue
- Don't commit .build directory or other generated files
- Don't use complex nested closures - extract to functions
- Don't mix tabs and spaces in same file

### Key Code References
- Arrow keys: 0x7B (left), 0x7C (right), 0x7E (up), 0x7D (down)
- Escape: 0x35
- Shift modifier: 1 << 17
- Use hex notation for all key codes