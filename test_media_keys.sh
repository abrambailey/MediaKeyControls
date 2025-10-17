#!/bin/bash

echo "🎵 Testing Media Key Capture"
echo ""
echo "This will show you recent MediaKeyControls logs"
echo "Press F8 a few times, then press Enter..."
read

echo ""
echo "Recent logs with [BC] prefix:"
log show --predicate 'eventMessage contains "[BC]"' --last 30s --style compact 2>/dev/null | grep "\[BC\]"

echo ""
echo "If you don't see logs above when you pressed F8:"
echo "  1. Check System Settings > Privacy & Security > Accessibility"
echo "  2. Make sure MediaKeyControls is enabled"
echo "  3. Try 'make rebuild' to reset permissions"
