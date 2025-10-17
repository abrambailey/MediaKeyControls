.PHONY: build run rebuild clean permissions

# Variables
APP_NAME = MediaKeyControls
BUNDLE_ID = com.mediakeycontrols
BUILD_DIR = build
SCHEME = MediaKeyControls
HOST_NAME = MediaKeyControlsHost
HOST_SOURCE = MediaControls/NativeMessagingHost.swift
CHROME_NATIVE_DIR = $(HOME)/Library/Application Support/Google/Chrome/NativeMessagingHosts

# Build the app
build: build-app build-host install-manifest
	@echo "✅ Build complete"

# Build the main app
build-app:
	@echo "Building $(APP_NAME)..."
	@xcodebuild -scheme $(SCHEME) \
		-configuration Release \
		build \
		CONFIGURATION_BUILD_DIR="$(PWD)/$(BUILD_DIR)" 2>&1 | \
		grep -E "(error|warning|BUILD|SUCCEEDED|FAILED)" || true

# Build the native messaging host binary
build-host:
	@echo "Building native messaging host..."
	@swiftc $(HOST_SOURCE) -o $(BUILD_DIR)/$(HOST_NAME) -O
	@chmod +x $(BUILD_DIR)/$(HOST_NAME)
	@echo "✅ Native host built"

# Install the native messaging manifest (only if it doesn't exist)
install-manifest:
	@echo "Checking native messaging manifest..."
	@mkdir -p "$(CHROME_NATIVE_DIR)"
	@if [ ! -f "$(CHROME_NATIVE_DIR)/$(BUNDLE_ID).json" ]; then \
		echo "Creating new manifest..."; \
		echo '{\n  "name": "$(BUNDLE_ID)",\n  "description": "Bandcamp Controls Native Host",\n  "path": "$(PWD)/$(BUILD_DIR)/$(HOST_NAME)",\n  "type": "stdio",\n  "allowed_origins": [\n    "chrome-extension://EXTENSION_ID_PLACEHOLDER/"\n  ]\n}' > "$(CHROME_NATIVE_DIR)/$(BUNDLE_ID).json"; \
		echo "⚠️  NOTE: You need to update EXTENSION_ID_PLACEHOLDER with your Chrome extension ID!"; \
	else \
		echo "✅ Manifest already exists, preserving extension ID"; \
	fi

# Run the app
run:
	@echo "Launching $(APP_NAME)..."
	@open $(BUILD_DIR)/$(APP_NAME).app

# Kill the app
kill:
	@echo "Stopping $(APP_NAME)..."
	@killall $(APP_NAME) 2>/dev/null || true
	@sleep 0.5

# Reset permissions
permissions:
	@echo "Resetting accessibility permissions..."
	@tccutil reset Accessibility $(BUNDLE_ID) 2>&1 || echo "Permission reset done"

# Full rebuild: kill, reset permissions, build, and run
rebuild: kill permissions build run
	@echo "✅ Full rebuild complete!"
	@echo "Grant accessibility permission when prompted, then test!"

# Clean build artifacts
clean: kill
	@echo "Cleaning build directory..."
	@rm -rf $(BUILD_DIR)
	@rm -rf DerivedData
	@echo "✅ Clean complete"

# Quick restart without rebuilding
restart: kill run

# Help
help:
	@echo "Available commands:"
	@echo "  make build      - Build the app"
	@echo "  make run        - Launch the app"
	@echo "  make rebuild    - Kill, reset permissions, build, and run"
	@echo "  make restart    - Kill and run (no rebuild)"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make permissions - Reset accessibility permissions"
	@echo "  make help       - Show this help"
