# Media Key Controls - Chrome Extension

This Chrome extension works with the MediaKey Controls macOS app to enable media key control of Bandcamp and YouTube playback.

## Installation

1. Open Chrome and go to `chrome://extensions/`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select the `MediaControlsExtension` folder
5. The extension should now appear in your extensions list

## How it works

- **content.js**: Runs on Bandcamp and YouTube pages and handles playback controls
- **background.js**: Communicates with the native macOS app via Native Messaging
- **manifest.json**: Extension configuration

Supported sites:
- ✅ Bandcamp (*.bandcamp.com)
- ✅ YouTube (youtube.com/watch)

## Testing

1. Open a Bandcamp or YouTube page
2. Open Chrome DevTools Console (F12 or Cmd+Option+I)
3. You should see: `[MediaKey Controls] Content script loaded on Bandcamp` (or YouTube)
4. The extension is ready to receive commands from the macOS app

To debug the background script:
1. Go to `chrome://extensions/`
2. Find "Media Key Controls"
3. Click "Inspect views: service worker"

## Permissions

- `nativeMessaging`: Required to communicate with the macOS app
- `*://*.bandcamp.com/*`: Required to run on Bandcamp pages
- `*://*.youtube.com/*`: Required to run on YouTube pages
- `storage`: Used to remember last active tab
- `tabs`: Required to find and activate media tabs
