#!/bin/bash

# Script to update the Chrome extension ID in the native messaging manifest

MANIFEST_PATH="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts/com.bandcamp.controls.json"

echo "🔧 Bandcamp Controls - Update Extension ID"
echo ""

if [ ! -f "$MANIFEST_PATH" ]; then
    echo "❌ Manifest file not found at: $MANIFEST_PATH"
    echo "Run 'make build' first to create it."
    exit 1
fi

echo "Current manifest contents:"
echo "---"
cat "$MANIFEST_PATH"
echo "---"
echo ""

read -p "Enter your Chrome extension ID: " EXTENSION_ID

if [ -z "$EXTENSION_ID" ]; then
    echo "❌ No extension ID provided"
    exit 1
fi

# Update the manifest file
sed -i '' "s/EXTENSION_ID_PLACEHOLDER/$EXTENSION_ID/" "$MANIFEST_PATH"

echo ""
echo "✅ Updated manifest file!"
echo ""
echo "New contents:"
echo "---"
cat "$MANIFEST_PATH"
echo "---"
echo ""
echo "You can now test the app with 'make run' or 'make rebuild'"
