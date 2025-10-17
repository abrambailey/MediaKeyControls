#!/bin/bash

# Complete rename from MediaKeyControls to MediaControls

echo "🔄 Completing rename to MediaKey Controls..."

# Update all remaining references in files
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.plist" -o -name "*.json" -o -name "Makefile" -o -name "*.entitlements" \) ! -path "./.git/*" ! -path "./build/*" -exec sed -i '' 's/MediaKeyControls/MediaControls/g' {} +

# Update bundle identifiers
find . -type f \( -name "*.sh" -o -name "*.md" -o -name "*.plist" -o -name "*.json" -o -name "Makefile" \) ! -path "./.git/*" ! -path "./build/*" -exec sed -i '' 's/com\.bandcamp\.controls/com.mediakeycontrols/g' {} +

# Update specific paths and references
sed -i '' 's/MediaControlsExtension/MediaControlsExtension/g' $(find . -type f \( -name "*.sh" -o -name "*.md" -o -name "Makefile" \) ! -path "./.git/*" ! -path "./build/*")

echo "✅ Rename complete!"
echo ""
echo "Updated references in:"
echo "  • Scripts (.sh files)"
echo "  • Documentation (.md files)"  
echo "  • Configuration (.plist, .json, Makefile)"
echo ""
