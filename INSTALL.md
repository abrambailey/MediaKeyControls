# Installation Guide

This guide will help you install MediaKey Controls for macOS in just a few minutes.

## Quick Install (Recommended)

The easiest way to install is using the automated install script:

```bash
./install.sh
```

The script will:
1. ✅ Check system requirements
2. 📦 Build the menu bar app
3. 🚀 Launch the app
4. 🧩 Guide you through Chrome extension setup (optional)

Just follow the prompts!

---

## Manual Installation

If you prefer to install manually or want more control:

### Prerequisites

- macOS 12.0 or later
- Apple Silicon Mac (M1/M2/M3)
- Xcode Command Line Tools

Install Xcode Command Line Tools if you haven't already:
```bash
xcode-select --install
```

### Step 1: Build the App

```bash
# Create Xcode project (first time only)
./setup_xcode_project.sh

# Build and launch
make build
make run
```

Or do it all at once:
```bash
make rebuild
```

### Step 2: Grant Permissions

When you first run the app, macOS will ask for permissions:

1. **Accessibility Permission**
   - System Settings → Privacy & Security → Accessibility
   - Enable the toggle for "MediaKeyControls"
   - Required to capture media key presses

2. **Automation Permission**
   - You'll be prompted when the app tries to control a browser or Spotify
   - Click "OK" to allow
   - Required for controlling playback

### Step 3: Install Chrome Extension (Optional)

The Chrome extension enables smart tab detection and playback state monitoring. **Highly recommended for Bandcamp and YouTube support.**

#### Install Extension:

1. Open Google Chrome
2. Navigate to `chrome://extensions/`
3. Enable **Developer mode** (toggle in top-right corner)
4. Click **Load unpacked**
5. Select the `MediaControlsExtension` folder from this project
6. The extension will appear in your extensions list

#### Configure Extension:

7. Copy the **Extension ID** (long string like `abcdefghijk...`)
8. Run this command with your extension ID:
   ```bash
   ./update_extension_id.sh
   ```
   Or manually edit:
   ```bash
   nano ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json
   ```
   Replace `EXTENSION_ID_PLACEHOLDER` with your actual extension ID

9. Restart the app:
   ```bash
   make restart
   ```

---

## Supported Browsers

The extension works with:
- ✅ Google Chrome
- ✅ Chromium
- ✅ Brave Browser
- ✅ Microsoft Edge (with Chrome extensions)

Safari works without an extension via AppleScript.

---

## Verification

After installation, test your setup:

1. **Check Menu Bar**
   - Look for the ♫ icon in your menu bar
   - Click it to toggle media key capture

2. **Test With Spotify** (easiest to test)
   - Launch Spotify app
   - Play something
   - Press F8 (or Play/Pause key) - playback should toggle

3. **Test With Browser**
   - Open Bandcamp or YouTube in Chrome
   - Start playing media
   - Press F8 - playback should toggle

If media keys don't work:
- Check Accessibility permissions
- Make sure the menu bar icon shows the app is running
- Try restarting the app with `make restart`

---

## Troubleshooting

### Media keys not working at all
- ❌ Accessibility permission not granted
- 💡 Go to System Settings → Privacy & Security → Accessibility
- ✅ Enable "MediaKeyControls"

### Keys work for Spotify but not browser
- ❌ Chrome extension not installed or configured
- 💡 Follow Step 3 above to install the extension
- ✅ Make sure extension ID is correctly set in manifest

### Keys control wrong app/tab
- ❌ Multiple services are playing
- 💡 Focus the window/tab you want to control
- ✅ The app prioritizes what's in focus

### Extension not communicating with app
- ❌ Extension ID not configured
- 💡 Check the extension ID matches in:
  - Chrome extensions page
  - `~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json`
- ✅ Restart both Chrome and the app

### Build errors
- ❌ Xcode Command Line Tools not installed
- 💡 Run: `xcode-select --install`
- ✅ Try running `make clean` then `make build`

---

## Uninstallation

To remove the app:

```bash
# Stop the app
make kill

# Remove app files
rm -rf build/
rm -rf MediaKeyControls.xcodeproj

# Remove Chrome extension
# Just remove it from chrome://extensions/

# Remove native messaging manifest (optional)
rm ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json
```

---

## Development

### Building for Development

```bash
# Clean build
make clean

# Build + run
make rebuild

# Just run (no build)
make run

# Quick restart
make restart
```

### Viewing Logs

The app logs to Console.app:

1. Open Console.app
2. Search for "BC" or "Bandcamp Controls"
3. Filter by process: "MediaKeyControls"

Or use command line:
```bash
log stream --predicate 'process == "MediaKeyControls"' --level debug
```

### Chrome Extension Debugging

1. Open Chrome
2. Go to `chrome://extensions/`
3. Click "Details" on the Media Key Controls extension
4. Click "Inspect views: service worker" (for background.js)
5. Console will show logs for debugging

---

## Next Steps

- Read [README.md](README.md) for usage details
- Check [SETUP.md](SETUP.md) for development setup
- Report issues on GitHub

Enjoy your media controls! 🎵
