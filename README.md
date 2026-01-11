# ewvim

Use Vim mode everywhere on macOS.

## What is ewvim?

ewvim is a native macOS application that brings Vim's powerful editing capabilities to any text field, input box, or editable area across all applications. Built entirely in Swift and SwiftUI, it provides a lightweight and performant Vim-like experience.

## Features

- ✅ Pure Swift + SwiftUI implementation
- ✅ Vim navigation (h, j, k, l)
- ✅ Mode switching (Normal, Insert, Visual, Command)
- ✅ Global keyboard monitoring
- ✅ Accessibility API integration
- ✅ Key simulation
- ✅ Lightweight and performant

## Architecture

**Pure Native Swift** - Unlike Electron-based solutions, ewvim is built entirely with native macOS technologies:

- **Swift** - Core application logic
- **SwiftUI** - Modern, declarative UI framework
- **Accessibility API** - Direct macOS integration
- **CGEvent** - Low-level key simulation

## Project Structure

```
ewvim/
├── Sources/ewvim/
│   ├── App.swift              # App entry point
│   ├── Models/
│   │   └── VimModels.swift     # Data models and enums
│   ├── Views/
│   │   └── ContentView.swift  # Main SwiftUI view
│   ├── ViewModels/
│   │   └── VimViewModel.swift  # State management
│   ├── Services/
│   │   ├── VimCommandProcessor.swift  # Command parsing
│   │   ├── KeyboardMonitor.swift      # Global keyboard monitoring
│   │   ├── KeySimulator.swift         # Key simulation
│   │   └── AccessibilityService.swift # Accessibility API
│   └── Resources/
├── Package.swift               # Swift package definition
└── README.md
```

## Quick Start

### Prerequisites

- macOS 13.0 or later
- Xcode 15+ or Swift 5.9+ Command Line Tools

### Installation

```bash
# Build the project
swift build --configuration release

# Run the application
swift run ewvim
```

### Granting Permissions

On first run, grant Accessibility permissions when prompted:

1. **System Settings** → **Privacy & Security** → **Accessibility**
2. Find **ewvim** and enable it
3. Click **Quit & Reopen** when prompted

## Usage

### Basic Commands

- **Navigation**: `h` (left), `j` (down), `k` (up), `l` (right)
- **Mode Switching**:
  - `i` - Enter Insert mode
  - `v` - Enter Visual mode
  - `:` - Enter Command mode
  - `Escape` - Return to Normal mode

### Status Indicator

The status bar at the top shows:
- Current mode (color-coded)
- Current command buffer
- Accessibility status

## Development

### Building

```bash
# Debug build
swift build

# Release build
swift build --configuration release

# Run tests
swift test
```

### Running

```bash
# Debug run
swift run ewvim

# Release run
./.build/release/ewvim
```

### Project Status

**Alpha Development** - Basic framework complete. See [DEVELOPMENT.md](DEVELOPMENT.md) for details.

### Roadmap

- [ ] Full Vim command set
- [ ] Word-wise movement (w, b, e)
- [ ] Line-wise movement (0, $, ^)
- [ ] Search and replace
- [ ] Text editing commands (d, c, y, p)
- [ ] Macros
- [ ] Custom key bindings
- [ ] App-specific configurations

## Comparison with kindaVim

| Feature | ewvim | kindaVim |
|---------|-------|-----------|
| Technology | Pure Swift | Pure Swift |
| Open Source | ✅ Yes | ❌ No |
| License | MIT | Proprietary |
| Status | Alpha | Production |
| Commands | Basic | Full |

## Contributing

Contributions welcome! Focus areas:
- Additional Vim commands
- UI improvements
- Performance optimization
- Bug fixes
- Documentation

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by [kindaVim](https://kindavim.app)
- Built with Swift and SwiftUI