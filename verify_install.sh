#!/bin/bash

# Verify Installation
# Quick script to check if everything is properly installed

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔍 Verifying MediaKey Controls Installation"
echo "========================================"
echo ""

# Check if app is built
echo "📦 App Build:"
if [ -f "$PROJECT_DIR/build/MediaKeyControls.app/Contents/MacOS/MediaKeyControls" ]; then
    echo "  ✅ App is built"
    APP_BUILT=true
else
    echo "  ❌ App not found in build directory"
    APP_BUILT=false
fi

# Check if app is running
echo ""
echo "🏃 App Status:"
if pgrep -x "MediaKeyControls" > /dev/null; then
    echo "  ✅ App is running (PID: $(pgrep -x "MediaKeyControls"))"
    APP_RUNNING=true
else
    echo "  ❌ App is not running"
    APP_RUNNING=false
fi

# Check Xcode project
echo ""
echo "🛠️  Xcode Project:"
if [ -d "$PROJECT_DIR/MediaKeyControls.xcodeproj" ]; then
    echo "  ✅ Xcode project exists"
else
    echo "  ⚠️  Xcode project not found (will be created on install)"
fi

# Check source files
echo ""
echo "📝 Source Files:"
REQUIRED_FILES=(
    "MediaKeyControls/MediaKeyControls.swift"
    "MediaKeyControls/MediaKeyHandler.swift"
    "MediaKeyControls/BandcampController.swift"
    "MediaKeyControls/YouTubeController.swift"
)

ALL_FILES_PRESENT=true
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo "  ✅ $(basename "$file")"
    else
        echo "  ❌ $(basename "$file") - MISSING!"
        ALL_FILES_PRESENT=false
    fi
done

# Check Chrome extension
echo ""
echo "🧩 Chrome Extension:"
if [ -d "$PROJECT_DIR/MediaControlsExtension" ]; then
    echo "  ✅ Extension directory exists"

    if [ -f "$PROJECT_DIR/MediaControlsExtension/manifest.json" ]; then
        echo "  ✅ manifest.json present"
        EXT_VERSION=$(grep -o '"version": "[^"]*"' "$PROJECT_DIR/MediaControlsExtension/manifest.json" | cut -d'"' -f4)
        echo "  ℹ️  Extension version: $EXT_VERSION"
    fi

    if [ -f "$PROJECT_DIR/MediaControlsExtension/content.js" ]; then
        echo "  ✅ content.js present"
    fi

    if [ -f "$PROJECT_DIR/MediaControlsExtension/background.js" ]; then
        echo "  ✅ background.js present"
    fi
else
    echo "  ❌ Extension directory not found"
fi

# Check native messaging manifest
echo ""
echo "🔗 Native Messaging:"
MANIFEST_PATH="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json"
if [ -f "$MANIFEST_PATH" ]; then
    echo "  ✅ Native messaging manifest exists"

    if grep -q "EXTENSION_ID_PLACEHOLDER" "$MANIFEST_PATH"; then
        echo "  ⚠️  Extension ID not configured yet"
        echo "     Run: ./update_extension_id.sh"
    else
        EXT_ID=$(grep -o '"chrome-extension://[^/]*' "$MANIFEST_PATH" | cut -d'/' -f3)
        if [ -n "$EXT_ID" ]; then
            echo "  ✅ Extension ID configured: ${EXT_ID:0:20}..."
        fi
    fi
else
    echo "  ⚠️  Native messaging manifest not found"
    echo "     Will be created after first 'make build'"
fi

# Check permissions
echo ""
echo "🔐 Permissions:"
echo "  ℹ️  Accessibility: Check System Settings → Privacy & Security → Accessibility"
echo "  ℹ️  Automation: Granted on-demand when controlling apps"

# Summary
echo ""
echo "📊 Summary:"
echo "=========="

ISSUES=0

if [ "$APP_BUILT" = false ]; then
    echo "  ❌ App needs to be built"
    ((ISSUES++))
fi

if [ "$APP_RUNNING" = false ]; then
    echo "  ⚠️  App is not running"
fi

if [ "$ALL_FILES_PRESENT" = false ]; then
    echo "  ❌ Some source files are missing"
    ((ISSUES++))
fi

if [ "$ISSUES" -eq 0 ]; then
    echo "  ✅ No critical issues found!"
    echo ""
    echo "🎉 Installation looks good!"

    if [ "$APP_RUNNING" = false ]; then
        echo ""
        echo "To start the app:"
        echo "  make run"
    fi
else
    echo "  ⚠️  Found $ISSUES issue(s)"
    echo ""
    echo "To fix:"
    echo "  ./install.sh"
fi

echo ""
echo "📚 Next steps:"
echo "  • Test with Spotify: Launch Spotify, press F8"
echo "  • Test with browser: Open Bandcamp/YouTube, press F8"
echo "  • View logs: Console.app → search 'MediaKeyControls'"
echo "  • Troubleshoot: See INSTALL.md"
echo ""
