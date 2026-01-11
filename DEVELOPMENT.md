# Development Guide

## Overview

ewvim is a native macOS application built with Swift and SwiftUI. This guide covers the architecture, development setup, and coding conventions.

## Architecture

### Core Components

#### 1. App Layer (`App.swift`)
- Entry point for the application
- Sets up SwiftUI app lifecycle
- Configures app as accessory (not docked)

#### 2. Models (`Models/VimModels.swift`)
- **VimMode** - Enum for different modes (Normal, Insert, Visual, Command)
- **VimState** - Current state of Vim processor
- **VimCommand** - Parsed command types
- **VimError** - Error handling

#### 3. Views (`Views/ContentView.swift`)
- SwiftUI views using MVVM pattern
- **ContentView** - Main UI window
- **ModeIndicator** - Status bar component

#### 4. ViewModels (`ViewModels/VimViewModel.swift`)
- **@MainActor** - All UI updates on main thread
- **@Published** properties for SwiftUI reactivity
- Manages Vim state and command processing
- Coordinates between services

#### 5. Services
- **VimCommandProcessor** - Parses Vim commands
- **KeyboardMonitor** - Global keyboard event monitoring
- **KeySimulator** - Simulates key presses
- **AccessibilityService** - macOS Accessibility API wrapper

### Data Flow

```
Keyboard Event → KeyboardMonitor
                    ↓
              VimViewModel
                    ↓
           VimCommandProcessor
                    ↓
              KeySimulator
                    ↓
            Application Output
```

## Development Setup

### Prerequisites

1. **Xcode** (recommended) or Swift Command Line Tools
2. **macOS 13.0+**
3. **Swift 5.9+**

### IDE Setup

#### Using Xcode (Recommended)

```bash
# Generate Xcode project
swift package generate-xcodeproj

# Open in Xcode
open ewvim.xcodeproj
```

#### Using VS Code

Install the Swift extension:
- [Swift for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=sswg.swift-lang)

### Build Commands

```bash
# Debug build
swift build

# Release build
swift build --configuration release

# Clean build
swift package clean
swift build --configuration release
```

### Running the App

```bash
# Run directly
swift run ewvim

# Run with logging
EWVIM_LOG=debug swift run ewvim
```

## Coding Conventions

### Swift Conventions

1. **Naming**: Use camelCase for variables/functions, PascalCase for types
2. **Access Control**: Default to `private`, expose as needed
3. **Error Handling**: Use Swift's `Result` type or custom `Error` enums
4. **Async**: Use Swift Concurrency (`async/await`, `Task`)
5. **Memory Management**: Prefer `weak` references in closures

### SwiftUI Conventions

1. **Views**: Small, focused components
2. **State**: Use `@State` for local state, `@Published` for shared state
3. **Modifiers**: Chain modifiers logically
4. **Previews**: Add `#Preview` blocks for all views

### Example Service

```swift
import Foundation

class MyService {
  static let shared = MyService()
  private init() {}

  func performAction() async -> Result<String, Error> {
    // Implementation
  }
}
```

## Adding New Vim Commands

### 1. Add Command to VimCommand Enum

```swift
enum VimCommand {
  // Existing commands...
  case myNewCommand
}
```

### 2. Implement Parsing in VimCommandProcessor

```swift
func parseCommand(_ buffer: String) -> VimCommand {
  switch buffer.lowercased() {
  // Existing cases...
  case "x":
    return .myNewCommand
  default:
    return .unknown
  }
}
```

### 3. Handle Command in ViewModel

```swift
private func handleNormalMode(_ key: String) {
  // Existing code...
  case .myNewCommand:
    executeMyNewCommand()
    clearCommand()
}
```

### 4. Implement the Action

```swift
private func executeMyNewCommand() {
  KeySimulator.press(keyCode: 0x00) // Example key code
}
```

## Testing

### Unit Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter MyTestClass
```

### Manual Testing

1. Run the app: `swift run ewvim`
2. Grant Accessibility permissions
3. Open any text editor (TextEdit, Notes, etc.)
4. Test Vim commands

## Debugging

### Logging

Add logging throughout the code:

```swift
print("Debug message: \(variable)")
```

### Xcode Debugger

When using Xcode:
- Set breakpoints
- Use LLDB console
- View variable values

### Common Issues

#### Accessibility Permissions Not Granted

```swift
// Check in code
if !AccessibilityService.shared.isEnabled {
  print("Accessibility not enabled")
}
```

#### Keyboard Monitor Not Working

Ensure the app has proper permissions and is not blocked by other apps.

#### Key Codes Reference

Common key codes (`KeyCode.swift` in Carbon framework):
- `0x00`: a
- `0x04`: h
- `0x26`: j
- `0x28`: k
- `0x25`: l
- `0x33`: Escape
- `0x7B-0x7E`: Arrow keys

## Performance

### Memory Management

- Use `weak` references in closures to avoid retain cycles
- Release `CFMachPort` when stopping keyboard monitoring
- Clean up resources in `deinit`

### CPU Usage

- Keep keyboard event handlers minimal
- Use async for long-running operations
- Avoid blocking the main thread

## Security

### Accessibility Permissions

The app requires Accessibility permissions to:
- Monitor keyboard events
- Read focused UI element text
- Set selected text ranges

These permissions are granted by the user in System Settings.

### Sandboxing

The app is not currently sandboxed, which may change in future releases for App Store distribution.

## Deployment

### Building for Distribution

```bash
# Release build
swift build --configuration release

# Copy to Applications
cp .build/release/ewvim /Applications/
```

### Code Signing

For distribution, code sign the app:

```bash
codesign --force --deep --sign "Developer ID" .build/release/ewvim
```

### Notarization

For macOS 13+, notarization is required:

```bash
xcrun notarytool submit ewvim.zip --apple-id "..." --password "..." --team-id "..."
```

## Resources

### Documentation

- [Swift Language Guide](https://docs.swift.org/swift-book/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [macOS Accessibility API](https://developer.apple.com/documentation/accessibility)
- [CGEvent Reference](https://developer.apple.com/documentation/coregraphics/cgevent)

### Similar Projects

- [kindaVim](https://kindavim.app) - Commercial inspiration
- [SketchyVim](https://github.com/FelixKratz/SketchyVim) - Open source alternative
- [Karabiner-Elements](https://karabiner-elements.pqrs.org) - Key remapping tool

## Contributing

### Workflow

1. Fork the repository
2. Create a feature branch
3. Implement changes
4. Add tests
5. Submit a pull request

### Code Review

Ensure:
- Code follows Swift conventions
- Tests are added/updated
- Documentation is updated
- No performance regressions

## Questions?

Check the [GitHub Issues](https://github.com/your-username/ewvim/issues) for common questions or open a new issue.