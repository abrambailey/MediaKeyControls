#!/bin/bash

# MediaKey Controls for macOS - Easy Install Script
# This script will build and install the menu bar app and guide you through Chrome extension setup

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "🎵 MediaKey Controls for macOS - Installation"
echo "==========================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This app only works on macOS"
    exit 1
fi

# Check if Xcode Command Line Tools are installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode Command Line Tools are not installed"
    echo ""
    echo "Please install them by running:"
    echo "  xcode-select --install"
    echo ""
    exit 1
fi

echo "✅ System requirements met"
echo ""

# Step 1: Build the app
echo "📦 Step 1: Building the app..."
echo "================================"
echo ""

if [ ! -d "MediaKeyControls.xcodeproj" ]; then
    echo "Creating Xcode project..."
    ./setup_xcode_project.sh
    echo ""
fi

echo "Building app (this may take a minute)..."
make build

if [ ! -f "build/MediaKeyControls.app/Contents/MacOS/MediaKeyControls" ]; then
    echo "❌ Build failed. Please check the output above for errors."
    exit 1
fi

echo "✅ App built successfully!"
echo ""

# Step 2: Clear existing permissions (fresh start)
echo "🔐 Step 2: Resetting permissions..."
echo "===================================="
echo ""

# Kill any existing instance first
killall MediaKeyControls 2>/dev/null || true
sleep 0.5

# Reset accessibility permissions to ensure clean state
echo "Clearing any existing accessibility permissions..."
tccutil reset Accessibility com.mediakeycontrols 2>/dev/null || true
echo "✅ Permissions cleared (you'll be prompted to grant them again)"
echo ""

# Step 3: Launch the app
echo "🚀 Step 3: Launching the app..."
echo "================================"
echo ""

# Launch the app
open build/MediaKeyControls.app

echo "✅ App launched! Look for the music note (♫) icon in your menu bar."
echo ""
echo "⚠️  You'll be prompted to grant permissions:"
echo "    1. Accessibility: Required to capture media keys"
echo "    2. Automation: Required to control browsers and Spotify"
echo ""
echo "    Please grant these permissions in System Settings"
echo ""
read -p "Press Enter once you've granted the permissions..."
echo ""

# Step 4: Chrome Extension (Required for Bandcamp)
echo "🧩 Step 4: Chrome Extension (Required for Bandcamp)"
echo "====================================================="
echo ""
echo "The Chrome extension is REQUIRED for Bandcamp next/prev controls."
echo "YouTube and Spotify work without it, but Bandcamp needs the extension."
echo ""

read -p "Install Chrome extension now? (y/n): " install_ext

if [[ "$install_ext" =~ ^[Yy]$ ]]; then
    ./install_extension.sh
else
    echo ""
    echo "⚠️  Skipping extension installation."
    echo "    You can install it later by running: ./install_extension.sh"
    echo ""
    echo "    Note: Bandcamp controls will NOT work without it!"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
if [[ "$install_ext" =~ ^[Yy]$ ]]; then
    echo "⚠️  REMINDER: Restart Chrome completely (Cmd+Q) for the extension to work!"
    echo ""
fi
echo "🎉 You're all set! Here's how to use your media controls:"
echo ""
echo "Media Keys:"
echo "  • F8 or Play/Pause: Toggle playback"
echo "  • F9 or Next: Skip forward"
echo "  • F7 or Previous: Skip backward/restart"
echo ""
echo "Supported Services:"
echo "  • Bandcamp (in browser with extension)"
echo "  • YouTube (in browser)"
echo "  • Spotify (native app)"
echo ""
echo "Priority Order:"
echo "  1. Whatever is actively playing"
echo "  2. Whatever tab/app is in focus"
echo "  3. Whatever was last controlled"
echo "  4. Spotify if open"
echo ""
echo "Menu Bar:"
echo "  • Look for the ♫ icon in your menu bar"
echo "  • Click it to toggle media key capture on/off"
echo "  • The app will run automatically on next login"
echo ""
echo "Troubleshooting:"
echo "  • If media keys don't work, check Accessibility permissions"
echo "  • If browser control doesn't work, check Automation permissions"
echo "  • If extension doesn't work, make sure Chrome was restarted"
echo "  • Run 'make rebuild' to rebuild and restart the app"
echo ""
echo "For more help, see: README.md"
echo ""
