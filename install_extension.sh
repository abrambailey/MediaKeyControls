#!/bin/bash

# Simple Chrome Extension Installer for MediaKey Controls

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST_PATH="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.mediakeycontrols.json"

echo "🧩 MediaKey Controls - Chrome Extension Installer"
echo "=================================================="
echo ""
echo "This will install the Chrome extension needed for Bandcamp control."
echo ""

# Open Chrome to extensions page
echo "Opening Chrome extensions page..."
open -a "Google Chrome" "chrome://extensions/" 2>/dev/null || {
    echo "⚠️  Could not open Chrome automatically"
    echo "Please open Chrome and go to: chrome://extensions/"
    echo ""
    read -p "Press Enter when ready..."
}

sleep 2

# Open extension folder
echo ""
echo "Opening extension folder..."
open "$PROJECT_DIR/MediaControlsExtension"

sleep 1

echo ""
echo "📋 Follow these steps in Chrome:"
echo ""
echo "1. In chrome://extensions/"
echo "   → Turn ON 'Developer mode' (toggle in top-right)"
echo ""
echo "2. Click 'Load unpacked' button"
echo "   → Select the 'MediaControlsExtension' folder (just opened in Finder)"
echo ""
echo "3. After loading, you'll see 'Media Key Controls' extension"
echo "   → Under the name, find the Extension ID"
echo "   → It looks like: abcdefghijklmnopqrstuvwxyz123456"
echo "   → Copy this ID"
echo ""

read -p "Press Enter once you've copied the Extension ID..."

echo ""
read -p "Paste the Extension ID here: " EXT_ID

if [ -z "$EXT_ID" ]; then
    echo ""
    echo "❌ No Extension ID provided. Exiting."
    exit 1
fi

# Check if manifest exists
if [ ! -f "$MANIFEST_PATH" ]; then
    echo ""
    echo "⚠️  Native messaging manifest not found."
    echo "    Restarting the app to create it..."
    killall MediaKeyControls 2>/dev/null || true
    sleep 1
    open "$PROJECT_DIR/build/MediaKeyControls.app"
    sleep 3
fi

# Update manifest
if [ -f "$MANIFEST_PATH" ]; then
    sed -i '' "s/EXTENSION_ID_PLACEHOLDER/$EXT_ID/g" "$MANIFEST_PATH"
    echo ""
    echo "✅ Extension configured successfully!"
    echo ""
    echo "📌 Final step: Restart Chrome for changes to take effect"
    echo ""
    echo "Then test Bandcamp controls:"
    echo "  • Open any Bandcamp album"
    echo "  • Press F8 (play/pause), F9 (next), F7 (previous)"
    echo ""
else
    echo ""
    echo "❌ Could not find manifest file. Please report this issue."
    exit 1
fi
