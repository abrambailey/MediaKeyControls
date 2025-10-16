# Bandcamp Media Key Controls - Setup Guide

This app allows you to control Bandcamp playback in Chrome using your Mac's media function keys (F7/F8/F9).

## Features

- ✅ Control Bandcamp with F7 (Previous), F8 (Play/Pause), F9 (Next)
- ✅ Works even when Bandcamp tab is in the background
- ✅ Remembers which Bandcamp tab you were using
- ✅ **Toggle on/off** to switch between Bandcamp and other apps (Spotify, etc.)
- ✅ Auto-start on login (optional)

## Architecture

The system consists of three components:
1. **macOS Menu Bar App** - Captures media key presses (can be toggled on/off)
2. **Native Messaging Host** - Bridges the Mac app and Chrome extension
3. **Chrome Extension** - Executes button clicks on Bandcamp pages

## Setup Instructions

### Step 1: Install the Chrome Extension

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right corner)
3. Click "Load unpacked"
4. Select the `BandcampExtension` folder from this project
5. The extension should now appear in your extensions list

### Step 2: Get the Extension ID

1. In `chrome://extensions/`, find "Bandcamp Media Key Controls"
2. Copy the **Extension ID** (it looks like: `abcdefghijklmnopqrstuvwxyz123456`)
3. Keep this ID handy for the next step

### Step 3: Update the Native Messaging Manifest

1. Open this file in a text editor:
   ```
   ~/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json
   ```

2. Replace `EXTENSION_ID_PLACEHOLDER` with your actual extension ID:
   ```json
   {
     "name": "com.bandcamp.controls",
     "description": "Bandcamp Controls Native Host",
     "path": "/Users/abram/Desktop/Apps/hotkeys/build/BandcampControlsHost",
     "type": "stdio",
     "allowed_origins": [
       "chrome-extension://YOUR_ACTUAL_EXTENSION_ID_HERE/"
     ]
   }
   ```

3. Save the file

### Step 4: Grant Accessibility Permissions

1. Run `make rebuild` to launch the app
2. When prompted, grant Accessibility permissions in System Settings
3. The music note icon should appear in your menu bar

### Step 5: Test the Setup

1. Open a Bandcamp page in Chrome (e.g., https://bandcamp.com)
2. Open Chrome DevTools Console (Cmd+Option+J)
3. You should see: `[Bandcamp Controls] Content script loaded`
4. Try using the menu bar app:
   - Click the music note icon
   - Select "Test Play/Pause" to verify the connection

### Step 6: Use Media Keys

Once everything is set up:
- **F8 (or Play/Pause)** - Play or pause the current track
- **F9 (or Next)** - Skip to next track
- **F7 (or Previous)** - Go to previous track or restart current track

## Troubleshooting

### Extension not connecting
1. Check Chrome DevTools Console for errors
2. Verify the extension ID in the manifest matches the actual ID
3. Try reloading the extension in `chrome://extensions/`

### Media keys not working
1. Check Accessibility permissions in System Settings
2. Look at Console.app and filter for `[BC]` to see app logs
3. Try the "Check Permissions" option in the menu bar menu

### Native host not responding
1. Check the log file: `/tmp/bandcamp_native_host.log`
2. Verify the path in the manifest file is correct
3. Try rebuilding with `make rebuild`

## Usage

### Toggle Media Key Capture

The app includes an **on/off toggle** so you can easily switch between controlling Bandcamp and other apps:

1. **Click the music note icon** in your menu bar
2. **Click "Media Keys Enabled"** (or press Cmd+E)
3. When disabled, media keys will pass through to Spotify, Apple Music, etc.
4. Toggle back on when you want to control Bandcamp again

**The toggle state persists across app restarts.**

### Auto-Start on Login

To make the app launch automatically when you log in:

```bash
cd /Users/abram/Desktop/Apps/hotkeys
./enable_autostart.sh
```

Or manually:
1. Open **System Settings** → **General** → **Login Items**
2. Click the **+** button
3. Navigate to `/Users/abram/Desktop/Apps/hotkeys/build/BandcampControls.app`
4. Click **Add**

**Note:** The Chrome extension will auto-connect when Chrome starts. No additional setup needed!

## Development Commands

```bash
make build      # Build app and native host
make rebuild    # Full rebuild with permission reset
make run        # Launch the app
make restart    # Restart without rebuilding
make clean      # Clean build artifacts
```

## Logs

- **App logs**: Console.app → filter for `[BC]`
- **Native host logs**: `/tmp/bandcamp_native_host.log`
- **Chrome logs**: DevTools Console on Bandcamp pages (service worker)
