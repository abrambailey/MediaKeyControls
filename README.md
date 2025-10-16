# Bandcamp Controls for macOS

A lightweight menu bar app that lets you control Bandcamp playback using your Mac's media keys (play/pause, next, previous).

## Features

- Control Bandcamp player with function keys (F7-F9) or media keys
- Works with Safari, Chrome, Chromium, and Brave browsers
- Runs quietly in the menu bar
- Apple Silicon native support

## Requirements

- macOS 12.0 or later
- Apple Silicon Mac
- Xcode 14 or later

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project: **macOS > App**
3. Configure:
   - Product Name: `BandcampControls`
   - Interface: SwiftUI
   - Language: Swift
   - Uncheck "Use Core Data"
4. Save to this directory

### 2. Configure Project

1. In Xcode project navigator, delete the default `ContentView.swift` and `BandcampControlsApp.swift`
2. Add all `.swift` files from the `BandcampControls` folder to the project
3. Set `Info.plist` and `BandcampControls.entitlements` in Build Settings:
   - Select project > Target > Info
   - Choose custom `Info.plist` location
   - Select Signing & Capabilities > Add entitlements file

### 3. Build Settings

1. Set deployment target to macOS 12.0+
2. Set architecture to `arm64` (Apple Silicon only)
3. Disable App Sandbox in Signing & Capabilities (required for AppleScript)
4. Ensure entitlements file is properly linked

### 4. Build and Run

```bash
# From Xcode
⌘ + R

# Or from command line
xcodebuild -scheme BandcampControls -configuration Release build
```

## Quick Setup Script

Alternatively, use the provided script to set up the Xcode project automatically:

```bash
./setup_xcode_project.sh
```

## Usage

1. Launch the app - you'll see a music note icon in your menu bar
2. Grant Accessibility permissions when prompted (System Settings > Privacy & Security > Accessibility)
3. Grant Automation permissions for your browser when prompted
4. Open Bandcamp in Safari, Chrome, or Brave
5. Use your media keys:
   - **F8 / Play/Pause**: Toggle playback
   - **F9 / Next**: Skip to next track
   - **F7 / Previous**: Skip to previous track or restart current track

## How It Works

- Captures media key events using CGEventTap
- Injects JavaScript into Bandcamp tabs via AppleScript
- Simulates button clicks on Bandcamp's player controls

## Permissions Required

- **Accessibility**: To capture media key presses
- **Automation**: To control Safari/Chrome and inject JavaScript

## Troubleshooting

**Media keys not working?**
- Check Accessibility permissions in System Settings
- Make sure the app is running (check menu bar)

**Browser control not working?**
- Grant Automation permission to the app
- Make sure you have a Bandcamp tab open
- Check that Bandcamp is actually playing music

**Keys controlling other apps?**
- The app captures media keys to prevent other apps from receiving them
- Close other music apps if they're interfering

## License

MIT
