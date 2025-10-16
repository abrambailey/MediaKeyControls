# Bandcamp Media Key Controls - Chrome Extension

This Chrome extension works with the BandcampControls macOS app to enable media key control of Bandcamp playback.

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select the `BandcampExtension` folder
5. The extension should now appear in your extensions list

## How it works

- **content.js**: Runs on all bandcamp.com pages and handles button clicks
- **background.js**: Communicates with the native macOS app via Native Messaging
- **manifest.json**: Extension configuration

## Testing

1. Open a Bandcamp page
2. Open Chrome DevTools Console
3. You should see: `[Bandcamp Controls] Content script loaded`
4. The extension is ready to receive commands from the macOS app

## Permissions

- `nativeMessaging`: Required to communicate with the macOS app
- `*://*.bandcamp.com/*`: Required to run on Bandcamp pages
