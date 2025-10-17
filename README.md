# MediaKey Controls for macOS

A lightweight menu bar app that lets you control Bandcamp, YouTube, and Spotify playback using your Mac's media keys (play/pause, next, previous).

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

## License

MIT
