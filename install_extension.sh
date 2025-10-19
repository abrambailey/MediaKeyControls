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
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1️⃣  In chrome://extensions/"
echo "      → Turn ON 'Developer mode' (toggle in top-right)"
echo ""
echo "  2️⃣  Click 'Load unpacked' button"
echo "      → Select the 'MediaControlsExtension' folder (just opened in Finder)"
echo ""
echo "  3️⃣  After loading, you'll see 'Media Key Controls' extension"
echo "      → Find the 'ID:' field under the extension name"
echo "      → It looks like: abcdefghijklmnopqrstuvwxyz123456"
echo "      → Copy this entire ID (click the copy button next to it)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
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
    # Check if placeholder exists before replacing
    if grep -q "EXTENSION_ID_PLACEHOLDER" "$MANIFEST_PATH"; then
        sed -i '' "s/EXTENSION_ID_PLACEHOLDER/$EXT_ID/g" "$MANIFEST_PATH"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ Extension configured successfully!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "📝 Updated manifest:"
        cat "$MANIFEST_PATH"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  IMPORTANT: You MUST restart Chrome for this to work!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  1. Quit Chrome COMPLETELY (Cmd+Q)"
        echo "     → Not just closing the window - fully quit the app"
        echo ""
        echo "  2. Reopen Chrome"
        echo "     → The extension will now be able to communicate with the app"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🧪 Then test the controls:"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "  • Open Bandcamp: https://bandcamp.com/"
        echo "  • Play any album"
        echo "  • Press F8 (play/pause), F9 (next), F7 (previous)"
        echo ""
        echo "💡 Tip: Check Console.app and search for 'MC' to see debug logs"
        echo ""
    else
        echo ""
        echo "⚠️  Extension ID already configured in manifest!"
        echo ""
        read -p "Do you want to replace it with the new ID? (y/n): " replace
        if [[ "$replace" =~ ^[Yy]$ ]]; then
            # Replace the existing extension ID (find the pattern in allowed_origins)
            sed -i '' "s|chrome-extension://[^/]*/|chrome-extension://$EXT_ID/|g" "$MANIFEST_PATH"
            echo "✅ Extension ID updated!"
        else
            echo "Keeping existing configuration."
        fi
    fi
else
    echo ""
    echo "❌ Could not find manifest file. Please report this issue."
    echo "Expected location: $MANIFEST_PATH"
    exit 1
fi
