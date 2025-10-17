#!/bin/bash

# Script to enable MediaKeyControls to launch at login

APP_PATH="$(pwd)/build/MediaKeyControls.app"
APP_NAME="MediaKeyControls"

echo "🎵 MediaKeyControls - Enable Auto-Start"
echo ""

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found at: $APP_PATH"
    echo "Please run 'make build' first!"
    exit 1
fi

echo "📦 App found at: $APP_PATH"
echo ""

# Add to Login Items using osascript
echo "Adding to Login Items..."
osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$APP_PATH\", hidden:false}"

if [ $? -eq 0 ]; then
    echo "✅ Successfully added to Login Items!"
    echo ""
    echo "📝 Notes:"
    echo "  • The app will now launch automatically when you log in"
    echo "  • You can verify in System Settings > General > Login Items"
    echo "  • Use Cmd+E in the menu to toggle media key capture on/off"
    echo "  • When disabled, media keys will work with Spotify, etc."
else
    echo "❌ Failed to add to Login Items"
    echo ""
    echo "Manual steps:"
    echo "1. Open System Settings"
    echo "2. Go to General > Login Items"
    echo "3. Click the '+' button"
    echo "4. Navigate to: $APP_PATH"
    echo "5. Click 'Add'"
fi
