import Cocoa
import ApplicationServices

// Spotify Controller - inline for simplicity
class SpotifyController {
    func isSpotifyRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.spotify.client" }
    }

    func isSpotifyPlaying() -> Bool {
        let script = """
        tell application "Spotify"
            if it is running then
                return player state as string
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let result = scriptObject.executeAndReturnError(&error)
            if error == nil {
                let state = result.stringValue ?? ""
                return state == "playing"
            }
        }
        return false
    }

    func togglePlayPause() {
        executeSpotifyCommand("playpause")
    }

    func skipForward() {
        executeSpotifyCommand("next track")
    }

    func skipBackward() {
        executeSpotifyCommand("previous track")
    }

    private func executeSpotifyCommand(_ command: String) {
        let script = """
        tell application "Spotify"
            \(command)
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let err = error {
                NSLog("[BC] ❌ Spotify command failed: \(err)")
            }
        }
    }
}

enum MediaTarget: String {
    case bandcamp
    case spotify
}

class MediaKeyHandler {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = true // Toggle for enabling/disabling capture
    private var hasBandcampTabs = false // Track if Bandcamp tabs exist
    private var isBandcampPlaying = false // Track if any Bandcamp tab is playing
    private var lastTabCheckTime: TimeInterval = 0
    private var lastUsedTarget: MediaTarget? = nil // Track what was used last
    private var lastSuccessTime: TimeInterval = 0 // When we last successfully controlled something
    private let spotifyController = SpotifyController()

    // Media key codes
    private let NX_KEYTYPE_PLAY = Int32(16)
    private let NX_KEYTYPE_FAST = Int32(17)
    private let NX_KEYTYPE_REWIND = Int32(18)
    private let NX_KEYTYPE_PREVIOUS = Int32(20)
    private let NX_KEYTYPE_NEXT = Int32(19)

    init() {
        // Load saved state
        isEnabled = UserDefaults.standard.bool(forKey: "mediaKeysEnabled")
        if UserDefaults.standard.object(forKey: "mediaKeysEnabled") == nil {
            // First time - default to enabled
            isEnabled = true
            UserDefaults.standard.set(true, forKey: "mediaKeysEnabled")
        }
        NSLog("[BC] MediaKeyHandler initialized, enabled: \(isEnabled)")

        // Listen for tab state notifications from the extension
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTabStateNotification(_:)),
            name: NSNotification.Name("com.bandcamp.controls.tabstate"),
            object: nil
        )
    }

    @objc func handleTabStateNotification(_ notification: Notification) {
        if let hasTabs = notification.userInfo?["hasTabs"] as? Bool {
            let wasSuccess = hasTabs || (notification.userInfo?["success"] as? Bool) == true
            let isPlaying = (notification.userInfo?["isPlaying"] as? Bool) ?? false

            hasBandcampTabs = hasTabs
            isBandcampPlaying = isPlaying
            lastTabCheckTime = Date().timeIntervalSince1970

            // Track successful Bandcamp control
            if wasSuccess {
                lastUsedTarget = .bandcamp
                lastSuccessTime = Date().timeIntervalSince1970
                NSLog("[BC] ✅ Bandcamp control successful, updating last used target")
            }

            NSLog("[BC] Tab state updated: hasTabs=\(hasTabs), isPlaying=\(isPlaying)")
        }
    }

    func toggle() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: "mediaKeysEnabled")
        NSLog("[BC] Media key capture toggled: \(isEnabled)")
    }

    func getEnabled() -> Bool {
        return isEnabled
    }

    private func isSpotifyFrontmost() -> Bool {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return false }
        return frontmost.bundleIdentifier == "com.spotify.client"
    }

    private func isChromeFrontmost() -> Bool {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return false }
        return frontmost.bundleIdentifier == "com.google.Chrome" ||
               frontmost.bundleIdentifier == "com.google.Chrome.canary" ||
               frontmost.bundleIdentifier == "com.brave.Browser" ||
               frontmost.bundleIdentifier == "com.microsoft.edgemac"
    }

    func shouldCapture() -> Bool {
        // Always respect manual toggle
        if !isEnabled {
            return false
        }

        // Check if we have any target apps to control
        let timeSinceLastCheck = Date().timeIntervalSince1970 - lastTabCheckTime
        let haveBandcamp = timeSinceLastCheck < 5.0 && hasBandcampTabs
        let haveSpotify = spotifyController.isSpotifyRunning()

        // Capture if we have Bandcamp tabs OR Spotify running
        if haveBandcamp || haveSpotify {
            return true
        }

        // If no recent check, try anyway (will fall back to Spotify if needed)
        if timeSinceLastCheck >= 5.0 {
            return true
        }

        // No targets available
        return false
    }

    func startListening() {
        NSLog("[BC] 🎧 Creating event tap for media keys...")

        // Create event tap for system-defined events (which includes media keys)
        // NX_SYSDEFINED = 14
        let eventMask = CGEventMask(1 << 14)

        NSLog("[BC] Event mask: \(eventMask)")

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let handler = Unmanaged<MediaKeyHandler>.fromOpaque(refcon).takeUnretainedValue()
                return handler.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[BC] ❌ Failed to create event tap - check Accessibility permissions")
            return
        }

        self.eventTap = eventTap
        NSLog("[BC] ✅ Event tap created successfully")

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        NSLog("[BC] ✅ Media key listener started successfully")
    }

    func stopListening() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }

        print("Media key listener stopped")
    }

    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // Check if this is a system-defined event (media keys)
        // NX_SYSDEFINED = 14
        if type.rawValue == 14 {
            let nsEvent = NSEvent(cgEvent: event)

            // Media keys can have subtype 7 or 8 (NX_SUBTYPE_AUX_CONTROL_BUTTONS)
            if nsEvent?.subtype.rawValue == 8 || nsEvent?.subtype.rawValue == 7 {
                if let data1 = nsEvent?.data1 {
                    let keyCode = Int32((data1 & 0xFFFF0000) >> 16)
                    let keyFlags = data1 & 0x0000FFFF
                    let keyState = (keyFlags & 0xFF00) >> 8
                    let keyPressed = keyState == 0xA  // Key down event

                    // Check if we should capture this key
                    if !shouldCapture() {
                        if !isEnabled {
                            NSLog("[BC] 🔇 Media key capture manually disabled, passing through")
                        } else {
                            NSLog("[BC] 🔇 No Bandcamp tabs open, passing through to other apps")
                        }
                        return Unmanaged.passRetained(event)
                    }

                    NSLog("[BC] 🎹 Media key - subtype: \(nsEvent?.subtype.rawValue ?? -1), keyCode: \(keyCode), pressed: \(keyPressed)")

                    if keyPressed {
                        handleMediaKey(keyCode: keyCode)
                        // Consume the event so it doesn't propagate to other apps
                        NSLog("[BC] 🚫 Consuming media key event")
                        return nil
                    } else {
                        // Also consume key up events to prevent propagation
                        NSLog("[BC] 🚫 Consuming media key up event")
                        return nil
                    }
                }
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func handleMediaKey(keyCode: Int32) {
        NSLog("[BC] 🎵 Media key action: \(keyCode)")

        // Check what's available
        let timeSinceLastCheck = Date().timeIntervalSince1970 - lastTabCheckTime
        let bandcampAvailable = (timeSinceLastCheck < 5.0 && hasBandcampTabs) || timeSinceLastCheck >= 5.0
        let spotifyAvailable = spotifyController.isSpotifyRunning()
        let spotifyIsPlaying = spotifyController.isSpotifyPlaying()
        let bandcampIsPlaying = timeSinceLastCheck < 5.0 && isBandcampPlaying
        let spotifyIsFrontmost = isSpotifyFrontmost()
        let chromeIsFrontmost = isChromeFrontmost()

        NSLog("[BC] 📊 State: Spotify(avail=\(spotifyAvailable), playing=\(spotifyIsPlaying), front=\(spotifyIsFrontmost)) Bandcamp(avail=\(bandcampAvailable), playing=\(bandcampIsPlaying), front=\(chromeIsFrontmost))")

        var primaryTarget: MediaTarget? = nil
        var reason = ""

        // Priority 1: Actively playing app
        if spotifyIsPlaying && !bandcampIsPlaying {
            primaryTarget = .spotify
            reason = "Spotify is actively playing"
        } else if bandcampIsPlaying && !spotifyIsPlaying {
            primaryTarget = .bandcamp
            reason = "Bandcamp is actively playing"
        } else if spotifyIsPlaying && bandcampIsPlaying {
            // Both playing - prefer the one in focus, or last used
            if spotifyIsFrontmost {
                primaryTarget = .spotify
                reason = "Both playing, Spotify is frontmost"
            } else if chromeIsFrontmost {
                primaryTarget = .bandcamp
                reason = "Both playing, Chrome is frontmost"
            } else if let last = lastUsedTarget {
                primaryTarget = last
                reason = "Both playing, using last target: \(last.rawValue)"
            } else {
                primaryTarget = .bandcamp
                reason = "Both playing, defaulting to Bandcamp"
            }
        }
        // Priority 2: App currently in focus
        else if spotifyIsFrontmost && spotifyAvailable {
            primaryTarget = .spotify
            reason = "Spotify is frontmost"
        } else if chromeIsFrontmost && bandcampAvailable {
            primaryTarget = .bandcamp
            reason = "Chrome is frontmost with Bandcamp tabs"
        }
        // Priority 3: Most recently playing
        else if let last = lastUsedTarget {
            if last == .spotify && spotifyAvailable {
                primaryTarget = .spotify
                reason = "Last used: Spotify"
            } else if last == .bandcamp && bandcampAvailable {
                primaryTarget = .bandcamp
                reason = "Last used: Bandcamp"
            } else if last == .spotify && bandcampAvailable {
                primaryTarget = .bandcamp
                reason = "Last used (Spotify) unavailable, switching to Bandcamp"
            } else if last == .bandcamp && spotifyAvailable {
                primaryTarget = .spotify
                reason = "Last used (Bandcamp) unavailable, switching to Spotify"
            }
        }
        // Priority 4: Spotify if opened
        else if spotifyAvailable {
            primaryTarget = .spotify
            reason = "Spotify is running"
        }
        // Priority 5: Bandcamp tab if any opened
        else if bandcampAvailable {
            primaryTarget = .bandcamp
            reason = "Bandcamp tabs available"
        }

        NSLog("[BC] 🎯 Target: \(primaryTarget?.rawValue ?? "none") - \(reason)")

        // Send to target
        if let target = primaryTarget {
            sendToTarget(target: target, keyCode: keyCode)
        } else {
            NSLog("[BC] ⚠️ No targets available")
        }
    }

    private func sendToTarget(target: MediaTarget, keyCode: Int32) {
        switch target {
        case .bandcamp:
            sendToBandcamp(keyCode: keyCode)
        case .spotify:
            sendToSpotify(keyCode: keyCode)
        }
    }

    private func sendToBandcamp(keyCode: Int32) {
        var action: String?

        switch keyCode {
        case NX_KEYTYPE_PLAY:
            NSLog("[BC] ▶️  Play/Pause → Bandcamp")
            action = "playPause"
        case NX_KEYTYPE_NEXT, NX_KEYTYPE_FAST:
            NSLog("[BC] ⏭  Next track → Bandcamp")
            action = "next"
        case NX_KEYTYPE_PREVIOUS, NX_KEYTYPE_REWIND:
            NSLog("[BC] ⏮  Previous track → Bandcamp")
            action = "previous"
        default:
            NSLog("[BC] ❓ Unknown media key: \(keyCode)")
        }

        if let action = action {
            DistributedNotificationCenter.default().post(
                name: NSNotification.Name("com.bandcamp.controls.mediakey"),
                object: nil,
                userInfo: ["action": action]
            )
            NSLog("[BC] 📤 Posted notification for Bandcamp: \(action)")
        }
    }

    private func sendToSpotify(keyCode: Int32) {
        switch keyCode {
        case NX_KEYTYPE_PLAY:
            NSLog("[BC] ▶️  Play/Pause → Spotify")
            spotifyController.togglePlayPause()
        case NX_KEYTYPE_NEXT, NX_KEYTYPE_FAST:
            NSLog("[BC] ⏭  Next track → Spotify")
            spotifyController.skipForward()
        case NX_KEYTYPE_PREVIOUS, NX_KEYTYPE_REWIND:
            NSLog("[BC] ⏮  Previous track → Spotify")
            spotifyController.skipBackward()
        default:
            NSLog("[BC] ❓ Unknown media key: \(keyCode)")
            return
        }

        // Mark Spotify as last used target
        lastUsedTarget = .spotify
        lastSuccessTime = Date().timeIntervalSince1970
        NSLog("[BC] ✅ Spotify control sent, updating last used target")
    }

    deinit {
        stopListening()
    }
}
