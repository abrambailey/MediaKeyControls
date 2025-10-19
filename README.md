# MediaKey Controls for macOS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-12.0+-blue.svg)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Built with Claude Code](https://img.shields.io/badge/Built%20with-Claude%20Code-5A67D8.svg)](https://claude.com/claude-code)

A lightweight menu bar app that lets you control Bandcamp, YouTube, and Spotify playback using your Mac's media keys (play/pause, next, previous).

## Security Notice

**INSTALL AT YOUR OWN RISK**: This application was developed with assistance from [Claude Code](https://claude.com/claude-code), an AI-powered development tool. While efforts have been made to follow security best practices, this software:
- Requires accessibility permissions to intercept media key events
- Requires automation permissions to control browsers and apps
- Was developed with AI assistance and may contain undiscovered vulnerabilities

**We strongly recommend reviewing the source code before installation.** See [SECURITY.md](SECURITY.md) for details.

If you discover security issues, please submit a pull request with fixes or report them responsibly.

## Quick Start

**One-line install:**
```bash
./install.sh
```

That's it! The script will build the app, launch it, and guide you through Chrome extension setup.

For detailed instructions, see **[INSTALL.md](INSTALL.md)**

## Features

- Control Bandcamp, YouTube, and Spotify players with function keys (F7-F9) or media keys
- Intelligent routing: automatically selects the right service based on what's playing or focused
- Works with Safari, Chrome, Chromium, and Brave browsers (for Bandcamp and YouTube)
- Native Spotify app support via AppleScript
- Runs quietly in the menu bar
- Apple Silicon native support

## Requirements

- macOS 12.0 or later
- Apple Silicon Mac
- Xcode 14 or later

## Installation

See **[INSTALL.md](INSTALL.md)** for complete installation instructions.

### Quick Commands

```bash
# Automated install (recommended)
./install.sh

# Or manual build
make rebuild

# Just restart the app
make restart
```

## Usage

1. Launch the app - you'll see a music note icon in your menu bar
2. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)
3. Grant Automation permissions for your browser and Spotify when prompted
4. Open Bandcamp, YouTube, or Spotify:
   - Bandcamp/YouTube: Open in Safari, Chrome, or Brave
   - Spotify: Launch the Spotify app
5. Use your media keys:
   - **F8 / Play/Pause**: Toggle playback
   - **F9 / Next**: Skip to next track/video
   - **F7 / Previous**: Skip to previous track/video or restart current one

The app intelligently routes your media key presses to the right service based on:
- What's currently playing (highest priority)
- Which app/browser is in focus
- What you last controlled

## How It Works

- Captures media key events using CGEventTap
- Injects JavaScript into Bandcamp and YouTube tabs via AppleScript
- Controls Spotify app directly via AppleScript
- Intelligently routes commands to the appropriate service
- Simulates button clicks on web players' controls

## Permissions Required

- **Accessibility**: To capture media key presses
- **Automation**: To control Safari/Chrome (for Bandcamp/YouTube) and Spotify app via AppleScript

## Troubleshooting

**Media keys not working?**
- Check Accessibility permissions in System Settings
- Make sure the app is running (check menu bar)

**Browser control not working?**
- Grant Automation permission to the app
- Make sure you have a Bandcamp or YouTube tab open
- Check that the media is actually playing

**Spotify control not working?**
- Make sure Spotify app is running
- Grant Automation permission for Spotify

**Keys controlling wrong service?**
- The app prioritizes what's currently playing
- If multiple services are playing, focus the browser/app you want to control
- The app remembers your last choice and will prefer it when multiple services are available

**Keys controlling other apps?**
- The app captures media keys when any supported service is available
- Other music apps won't receive media keys while this app is active

## Contributing

Contributions are welcome, especially:
- Security audits and fixes
- Bug reports and fixes
- macOS compatibility testing
- Code review of AI-generated code
- Documentation improvements

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

This project was built with AI assistance. We welcome security-focused contributions and responsible disclosure of vulnerabilities.

See [SECURITY.md](SECURITY.md) for our security policy and how to report issues.

## Development Credits

This project was developed with assistance from [Claude Code](https://claude.com/claude-code), an AI-powered development tool by Anthropic.

## License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 Abram Bailey
