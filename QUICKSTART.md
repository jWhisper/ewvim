# Quick Start Guide

## 1. Prerequisites Check

Ensure you have the following installed:

```bash
# Check Swift version (needs 5.9+)
swift --version

# Check macOS version (needs 13+)
sw_vers
```

Expected output:
```
Apple Swift version 5.9.x
ProductName:	macOS
ProductVersion:	13.x.x
```

## 2. Build the Application

```bash
# Navigate to project directory
cd /path/to/ewvim

# Build the project
swift build --configuration release

# Verify the build
ls -la .build/release/ewvim
```

Expected output:
```
-rwxr-xr-x  1 user  staff  [size] [date] .build/release/ewvim
```

## 3. Run the Application

```bash
# Run the app
swift run ewvim
```

You should see:
- A window showing "ewvim" title
- A status bar at the top (black background)
- Mode indicator showing "NORMAL" (blue)
- Accessibility status indicator

## 4. Grant Accessibility Permissions

The app will prompt you for Accessibility permissions. If not prompted:

1. Open **System Settings**
2. Go to **Privacy & Security** → **Accessibility**
3. Click the **+** button
4. Navigate to `.build/release/ewvim` and select it
5. Toggle **ewvim** to **ON**
6. Click **Quit & Reopen** when prompted

## 5. Test Vim Commands

Once permissions are granted and the app is running:

### Basic Navigation

- Press `h` → Move left
- Press `j` → Move down
- Press `k` → Move up
- Press `l` → Move right

### Mode Switching

- Press `i` → Switch to INSERT mode (status bar turns red)
- Press `Escape` → Return to NORMAL mode
- Press `v` → Switch to VISUAL mode (status bar turns yellow)
- Press `:` → Switch to COMMAND mode (status bar turns purple)

### Verify Functionality

Open any text editor (TextEdit, Notes, Terminal, etc.) and try:
1. Type some text
2. Use `h`, `j`, `k`, `l` to navigate
3. Switch between modes

## 6. Using the App

### Status Bar Indicators

- **Blue**: Normal mode
- **Red**: Insert mode
- **Yellow**: Visual mode
- **Purple**: Command mode

### Current Command Display

The status bar also shows the current command buffer, which is useful when typing multi-key commands.

### Accessibility Status

- **Green check**: Accessibility enabled, ready to use
- **Orange warning**: Accessibility not enabled, functionality limited

## Troubleshooting

### Build Errors

**Error:** `error: unable to find utility "xcrun"`

**Solution:** Install Xcode Command Line Tools
```bash
xcode-select --install
```

**Error:** `error: manifest parse error(s)`

**Solution:** Ensure you're running Swift 5.9 or later
```bash
brew install swift
```

### Accessibility Permissions

**Error:** Commands don't work

**Solution:**
1. Verify permissions in System Settings
2. Quit and restart the app
3. Try disabling and re-enabling Accessibility

**Error:** "Accessibility not enabled" message persists

**Solution:**
1. Check if multiple versions of the app are running
2. Ensure the correct binary is added to Accessibility
3. Restart your Mac

### Keyboard Monitoring

**Error:** Keys not captured

**Solution:**
1. Ensure Accessibility is enabled
2. Check for conflicting apps (Karabiner, Hammerspoon, etc.)
3. Try disabling other keyboard utilities

**Error:** Keys captured but not processed

**Solution:**
1. Check the command buffer in status bar
2. Verify the command is implemented (see `VimCommandProcessor.swift`)
3. Check console logs for errors

### App Crashes

**Error:** App crashes on launch

**Solution:**
1. Run with logging enabled: `EWVIM_LOG=debug swift run ewvim`
2. Check crash logs in Console.app
3. Report the issue with crash logs

## Advanced Usage

### Running in Debug Mode

```bash
# Enable debug logging
EWVIM_LOG=debug swift run ewvim

# Run with Xcode debugger
lldb .build/debug/ewvim
```

### Building Debug Version

```bash
# Build debug version
swift build

# Run debug version
swift run ewvim
```

### Installing to Applications

```bash
# Copy to Applications folder
sudo cp .build/release/ewvim /Applications/

# Set executable permissions
sudo chmod +x /Applications/ewvim

# Run from Applications
open /Applications/ewvim
```

### Auto-launch on Startup

```bash
# Create launch agent
cat > ~/Library/LaunchAgents/com.ewvim.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.ewvim</string>
  <key>ProgramArguments</key>
  <array>
    <string>/Applications/ewvim</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
EOF

# Load the launch agent
launchctl load ~/Library/LaunchAgents/com.ewvim.plist
```

## Next Steps

1. **Read the Code**: Explore the source code to understand how it works
2. **Add Commands**: Implement new Vim commands (see [DEVELOPMENT.md](DEVELOPMENT.md))
3. **Customize**: Modify the UI or add new features
4. **Contribute**: Report bugs or submit pull requests

## Getting Help

- **Documentation**: [DEVELOPMENT.md](DEVELOPMENT.md), [README.md](README.md)
- **Issues**: [GitHub Issues](https://github.com/your-username/ewvim/issues)
- **Community**: [GitHub Discussions](https://github.com/your-username/ewvim/discussions)

## Keyboard Shortcuts Reference

| Key | Action | Mode |
|-----|--------|------|
| `h` | Move left | Normal/Visual |
| `j` | Move down | Normal/Visual |
| `k` | Move up | Normal/Visual |
| `l` | Move right | Normal/Visual |
| `i` | Enter Insert mode | Normal |
| `v` | Enter Visual mode | Normal |
| `:` | Enter Command mode | Normal |
| `Escape` | Return to Normal mode | Any |

## Performance Tips

- Close the app when not in use to free system resources
- Disable other keyboard utilities if experiencing conflicts
- Use the release build (`--configuration release`) for better performance