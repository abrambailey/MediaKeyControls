#!/bin/bash

# Test Installation from Scratch
# This script simulates a fresh install by cleaning all build artifacts and installations

set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_DIR"

echo "🧪 Testing Installation from Scratch"
echo "===================================="
echo ""
echo "This will:"
echo "  1. Stop the running app"
echo "  2. Clean all build artifacts"
echo "  3. Remove Xcode project"
echo "  4. Remove native messaging manifest"
echo "  5. Reset permissions"
echo "  6. Run fresh installation"
echo ""

read -p "Continue? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "🧹 Step 1: Cleaning up existing installation..."
echo "================================================"

# Stop the app
echo "  • Stopping app..."
killall MediaKeyControls 2>/dev/null && echo "    ✅ App stopped" || echo "    ℹ️  App not running"

# Clean build artifacts
echo "  • Removing build directory..."
rm -rf build/ && echo "    ✅ Build directory removed" || echo "    ⚠️  No build directory"

# Remove Xcode project
echo "  • Removing Xcode project..."
rm -rf MediaKeyControls.xcodeproj && echo "    ✅ Xcode project removed" || echo "    ℹ️  No Xcode project"

# Remove DerivedData
echo "  • Cleaning DerivedData..."
rm -rf DerivedData/ && echo "    ✅ DerivedData cleaned" || echo "    ℹ️  No DerivedData"

# Remove native messaging manifest
MANIFEST_PATH="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json"
if [ -f "$MANIFEST_PATH" ]; then
    echo "  • Removing native messaging manifest..."
    rm "$MANIFEST_PATH" && echo "    ✅ Manifest removed"
else
    echo "  • No native messaging manifest found"
fi

# Reset permissions (requires user password)
echo "  • Resetting accessibility permissions..."
tccutil reset Accessibility com.bandcamp.controls 2>&1 >/dev/null && echo "    ✅ Permissions reset" || echo "    ℹ️  Permissions already reset"

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📊 Current state:"
echo "  • Build directory: $([ -d build/ ] && echo 'EXISTS' || echo 'CLEAN')"
echo "  • Xcode project: $([ -d MediaKeyControls.xcodeproj ] && echo 'EXISTS' || echo 'CLEAN')"
echo "  • Native manifest: $([ -f "$MANIFEST_PATH" ] && echo 'EXISTS' || echo 'CLEAN')"
echo ""

# List source files to verify project structure
echo "📁 Source files present:"
ls -1 MediaKeyControls/*.swift | while read file; do
    echo "  ✅ $(basename "$file")"
done
echo ""

echo "🚀 Step 2: Running fresh installation..."
echo "========================================"
echo ""

read -p "Ready to test installation? (y/n): " ready

if [[ ! "$ready" =~ ^[Yy]$ ]]; then
    echo "Stopped. You can run './install.sh' manually when ready."
    exit 0
fi

echo ""
echo "🎬 Starting installation..."
echo ""

# Run the installation script
./install.sh

echo ""
echo "✅ Installation test complete!"
echo ""
echo "📝 Verification checklist:"
echo ""
echo "  [ ] Menu bar icon (♫) is visible"
echo "  [ ] Accessibility permission granted"
echo "  [ ] Automation permission granted (when triggered)"
echo "  [ ] Chrome extension loaded (if chosen)"
echo "  [ ] Extension ID configured (if chosen)"
echo "  [ ] Media keys work with Spotify"
echo "  [ ] Media keys work with browser tabs"
echo ""
echo "To manually verify:"
echo "  1. Look for ♫ icon in menu bar"
echo "  2. Open Spotify and press F8"
echo "  3. Open Bandcamp/YouTube and press F8"
echo "  4. Check Console.app for logs (process: MediaKeyControls)"
echo ""
