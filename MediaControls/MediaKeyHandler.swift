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
                NSLog("[MC] ❌ Spotify command failed: \(err)")
            }
        }
    }
}

enum MediaTarget: String {
    case bandcamp
    case spotify
    case youtube
}

class MediaKeyHandler {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = true // Toggle for enabling/disabling capture
    private var hasBandcampTabs = false // Track if Bandcamp tabs exist
    private var isBandcampPlaying = false // Track if any Bandcamp tab is playing
    private var lastTabCheckTime: TimeInterval = 0
    private var hasYouTubeTabs = false // Cached YouTube tab state
    private var isYouTubePlaying = false // Cached YouTube playing state
    private var lastYouTubeCheckTime: TimeInterval = 0
    private var lastUsedTarget: MediaTarget? = nil // Track what was used last
    private var lastSuccessTime: TimeInterval = 0 // When we last successfully controlled something
    private var lastCommandTime: TimeInterval = 0 // When we last sent a command (regardless of success)
    private let spotifyController = SpotifyController()
    private let youtubeController = YouTubeController()
    private var youtubeCheckTimer: Timer? = nil

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
        NSLog("[MC] MediaKeyHandler initialized, enabled: \(isEnabled)")

        // Listen for tab state notifications from the extension
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleTabStateNotification(_:)),
            name: NSNotification.Name("com.mediakeycontrols.tabstate"),
            object: nil
        )

        // Start periodic YouTube state check (in background to avoid blocking)
        youtubeCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.global(qos: .utility).async {
                self?.updateYouTubeState()
            }
        }
        // Do initial check
        DispatchQueue.global(qos: .utility).async {
            self.updateYouTubeState()
        }
    }

    private func updateYouTubeState() {
        let hasTabs = youtubeController.hasYouTubeTabs()
        let isPlaying = youtubeController.isYouTubePlaying()

        DispatchQueue.main.async { [weak self] in
            self?.hasYouTubeTabs = hasTabs
            self?.isYouTubePlaying = isPlaying
            self?.lastYouTubeCheckTime = Date().timeIntervalSince1970
            NSLog("[MC] YouTube state updated: hasTabs=\(hasTabs), isPlaying=\(isPlaying)")
        }
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
                NSLog("[MC] ✅ Bandcamp control successful, updating last used target")
            }

            NSLog("[MC] Tab state updated: hasTabs=\(hasTabs), isPlaying=\(isPlaying)")
        }
    }

    func toggle() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: "mediaKeysEnabled")
        NSLog("[MC] Media key capture toggled: \(isEnabled)")
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
        // IMPORTANT: This is called on the event tap callback and MUST be fast (<1ms)
        // or macOS will disable the event tap. Don't do expensive checks here!

        // Always capture to prevent Apple Music from opening
        // The actual target selection happens in handleMediaKey() where we can be slower
        return true
    }

    func startListening() {
        NSLog("[MC] 🎧 Creating event tap for media keys...")

        // Create event tap for system-defined events (which includes media keys)
        // NX_SYSDEFINED = 14
        let eventMask = CGEventMask(1 << 14)

        NSLog("[MC] Event mask: \(eventMask)")

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
            NSLog("[MC] ❌ Failed to create event tap - check Accessibility permissions")
            return
        }

        self.eventTap = eventTap
        NSLog("[MC] ✅ Event tap created successfully")

        // Create run loop source
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)

        NSLog("[MC] ✅ Media key listener started successfully")
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

                    // IMPORTANT: Only intercept our specific media keys (F7-F9 / Play, Next, Previous)
                    // Let other system keys (brightness, keyboard backlight, etc.) pass through
                    let isOurMediaKey = keyCode == NX_KEYTYPE_PLAY ||
                                        keyCode == NX_KEYTYPE_NEXT ||
                                        keyCode == NX_KEYTYPE_PREVIOUS ||
                                        keyCode == NX_KEYTYPE_FAST ||
                                        keyCode == NX_KEYTYPE_REWIND

                    if !isOurMediaKey {
                        // Not a media key we care about - pass through to system
                        return Unmanaged.passRetained(event)
                    }

                    // Check if we should capture this key
                    if !isEnabled {
                        // User manually disabled - pass through to other apps
                        NSLog("[MC] 🔇 Media key capture manually disabled, passing through")
                        return Unmanaged.passRetained(event)
                    }

                    if !shouldCapture() {
                        // No targets available - consume to prevent Apple Music from opening
                        NSLog("[MC] 🔇 No targets available, consuming event (do nothing)")
                        return nil
                    }

                    NSLog("[MC] 🎹 Media key - subtype: \(nsEvent?.subtype.rawValue ?? -1), keyCode: \(keyCode), pressed: \(keyPressed)")

                    if keyPressed {
                        handleMediaKey(keyCode: keyCode)
                        // Consume the event so it doesn't propagate to other apps
                        NSLog("[MC] 🚫 Consuming media key event")
                        return nil
                    } else {
                        // Also consume key up events to prevent propagation
                        NSLog("[MC] 🚫 Consuming media key up event")
                        return nil
                    }
                }
            }
        }

        return Unmanaged.passRetained(event)
    }

    private func handleMediaKey(keyCode: Int32) {
        NSLog("[MC] 🎵 Media key action: \(keyCode)")

        // Check what's available (using cached state to avoid slow AppleScript calls)
        let timeSinceLastCheck = Date().timeIntervalSince1970 - lastTabCheckTime
        let timeSinceYouTubeCheck = Date().timeIntervalSince1970 - lastYouTubeCheckTime
        let bandcampAvailable = timeSinceLastCheck < 5.0 && hasBandcampTabs
        let spotifyAvailable = spotifyController.isSpotifyRunning()
        let youtubeAvailable = timeSinceYouTubeCheck < 5.0 && hasYouTubeTabs
        let spotifyIsPlaying = spotifyController.isSpotifyPlaying()
        let youtubeIsPlaying = timeSinceYouTubeCheck < 5.0 && isYouTubePlaying
        let bandcampIsPlaying = timeSinceLastCheck < 5.0 && isBandcampPlaying
        let spotifyIsFrontmost = isSpotifyFrontmost()
        let chromeIsFrontmost = isChromeFrontmost()

        NSLog("[MC] 📊 State: Spotify(avail=\(spotifyAvailable), playing=\(spotifyIsPlaying), front=\(spotifyIsFrontmost)) Bandcamp(avail=\(bandcampAvailable), playing=\(bandcampIsPlaying)) YouTube(avail=\(youtubeAvailable), playing=\(youtubeIsPlaying), front=\(chromeIsFrontmost))")

        var primaryTarget: MediaTarget? = nil
        var reason = ""

        // Priority 0: If we just sent a command (within 1 second), stick with that target
        // This prevents rapid key presses from switching services before state updates arrive
        let timeSinceLastCommand = Date().timeIntervalSince1970 - lastCommandTime
        if timeSinceLastCommand < 1.0, let last = lastUsedTarget {
            let targetStillAvailable = (last == .spotify && spotifyAvailable) ||
                                       (last == .bandcamp && bandcampAvailable) ||
                                       (last == .youtube && youtubeAvailable)
            if targetStillAvailable {
                primaryTarget = last
                reason = "Recently commanded \(last.rawValue) (\(String(format: "%.1f", timeSinceLastCommand))s ago)"
                NSLog("[MC] 🎯 Target: \(primaryTarget!.rawValue) - \(reason)")
                sendToTarget(target: primaryTarget!, keyCode: keyCode)
                return
            }
        }

        // Priority 1: Whatever is actively playing
        let playingCount = [spotifyIsPlaying, bandcampIsPlaying, youtubeIsPlaying].filter { $0 }.count

        if playingCount == 1 {
            // Only one service is playing - use it
            if spotifyIsPlaying {
                primaryTarget = .spotify
                reason = "Spotify is actively playing"
            } else if bandcampIsPlaying {
                primaryTarget = .bandcamp
                reason = "Bandcamp is actively playing"
            } else if youtubeIsPlaying {
                primaryTarget = .youtube
                reason = "YouTube is actively playing"
            }
        } else if playingCount > 1 {
            // Multiple services playing - use the one in focus, or fall back to last used
            if spotifyIsFrontmost && spotifyIsPlaying {
                primaryTarget = .spotify
                reason = "Multiple playing, Spotify is frontmost"
            } else if chromeIsFrontmost {
                // Chrome is frontmost - check which service is playing
                if youtubeIsPlaying && bandcampIsPlaying {
                    // Both are playing in Chrome - prefer last used if it's one of them
                    if lastUsedTarget == .youtube {
                        primaryTarget = .youtube
                        reason = "Multiple playing, Chrome frontmost, YouTube was last used"
                    } else if lastUsedTarget == .bandcamp {
                        primaryTarget = .bandcamp
                        reason = "Multiple playing, Chrome frontmost, Bandcamp was last used"
                    } else {
                        // No clear preference, default to YouTube
                        primaryTarget = .youtube
                        reason = "Multiple playing, Chrome frontmost, defaulting to YouTube"
                    }
                } else if youtubeIsPlaying {
                    primaryTarget = .youtube
                    reason = "Multiple playing, Chrome frontmost with YouTube"
                } else if bandcampIsPlaying {
                    primaryTarget = .bandcamp
                    reason = "Multiple playing, Chrome frontmost with Bandcamp"
                }
            } else if let last = lastUsedTarget,
                      (last == .spotify && spotifyIsPlaying) ||
                      (last == .bandcamp && bandcampIsPlaying) ||
                      (last == .youtube && youtubeIsPlaying) {
                primaryTarget = last
                reason = "Multiple playing, using last active: \(last.rawValue)"
            } else {
                // No focus or last used preference - pick the first one playing
                if youtubeIsPlaying {
                    primaryTarget = .youtube
                    reason = "Multiple playing, defaulting to YouTube"
                } else if bandcampIsPlaying {
                    primaryTarget = .bandcamp
                    reason = "Multiple playing, defaulting to Bandcamp"
                } else if spotifyIsPlaying {
                    primaryTarget = .spotify
                    reason = "Multiple playing, defaulting to Spotify"
                }
            }
        }
        // Priority 2: If nothing playing, use whatever is in focus
        else if spotifyIsFrontmost && spotifyAvailable {
            primaryTarget = .spotify
            reason = "Nothing playing, Spotify is frontmost"
        } else if chromeIsFrontmost {
            // Chrome is frontmost - check which service is available
            if youtubeAvailable && bandcampAvailable {
                // Both available - prefer last used if it's one of them
                if lastUsedTarget == .youtube {
                    primaryTarget = .youtube
                    reason = "Nothing playing, Chrome frontmost, YouTube was last used"
                } else if lastUsedTarget == .bandcamp {
                    primaryTarget = .bandcamp
                    reason = "Nothing playing, Chrome frontmost, Bandcamp was last used"
                } else {
                    // No clear preference, default to YouTube
                    primaryTarget = .youtube
                    reason = "Nothing playing, Chrome frontmost, defaulting to YouTube"
                }
            } else if youtubeAvailable {
                primaryTarget = .youtube
                reason = "Nothing playing, Chrome frontmost with YouTube"
            } else if bandcampAvailable {
                primaryTarget = .bandcamp
                reason = "Nothing playing, Chrome frontmost with Bandcamp"
            }
        }
        // Priority 3: Use whatever was last active
        else if let last = lastUsedTarget {
            if last == .spotify && spotifyAvailable {
                primaryTarget = .spotify
                reason = "Last active: Spotify"
            } else if last == .bandcamp && bandcampAvailable {
                primaryTarget = .bandcamp
                reason = "Last active: Bandcamp"
            } else if last == .youtube && youtubeAvailable {
                primaryTarget = .youtube
                reason = "Last active: YouTube"
            }
        }
        // Priority 4: Fallback to Spotify if open
        if primaryTarget == nil && spotifyAvailable {
            primaryTarget = .spotify
            reason = "Fallback to Spotify"
        }

        // Priority 5: Do nothing if no valid target
        if let target = primaryTarget {
            NSLog("[MC] 🎯 Target: \(target.rawValue) - \(reason)")
            sendToTarget(target: target, keyCode: keyCode)
        } else {
            NSLog("[MC] ⚠️ No targets available, doing nothing")
        }
    }

    private func sendToTarget(target: MediaTarget, keyCode: Int32) {
        // Update command timestamp immediately to prevent rapid switches
        lastCommandTime = Date().timeIntervalSince1970
        lastUsedTarget = target

        switch target {
        case .bandcamp:
            sendToBandcamp(keyCode: keyCode)
        case .spotify:
            sendToSpotify(keyCode: keyCode)
        case .youtube:
            sendToYouTube(keyCode: keyCode)
        }
    }

    private func sendToBandcamp(keyCode: Int32) {
        var action: String?

        switch keyCode {
        case NX_KEYTYPE_PLAY:
            NSLog("[MC] ▶️  Play/Pause → Bandcamp")
            action = "playPause"
        case NX_KEYTYPE_NEXT, NX_KEYTYPE_FAST:
            NSLog("[MC] ⏭  Next track → Bandcamp")
            action = "next"
        case NX_KEYTYPE_PREVIOUS, NX_KEYTYPE_REWIND:
            NSLog("[MC] ⏮  Previous track → Bandcamp")
            action = "previous"
        default:
            NSLog("[MC] ❓ Unknown media key: \(keyCode)")
        }

        if let action = action {
            DistributedNotificationCenter.default().post(
                name: NSNotification.Name("com.mediakeycontrols.mediakey"),
                object: nil,
                userInfo: ["action": action]
            )
            NSLog("[MC] 📤 Posted notification for Bandcamp: \(action)")
        }
    }

    private func sendToSpotify(keyCode: Int32) {
        switch keyCode {
        case NX_KEYTYPE_PLAY:
            NSLog("[MC] ▶️  Play/Pause → Spotify")
            spotifyController.togglePlayPause()
        case NX_KEYTYPE_NEXT, NX_KEYTYPE_FAST:
            NSLog("[MC] ⏭  Next track → Spotify")
            spotifyController.skipForward()
        case NX_KEYTYPE_PREVIOUS, NX_KEYTYPE_REWIND:
            NSLog("[MC] ⏮  Previous track → Spotify")
            spotifyController.skipBackward()
        default:
            NSLog("[MC] ❓ Unknown media key: \(keyCode)")
            return
        }

        lastSuccessTime = Date().timeIntervalSince1970
        NSLog("[MC] ✅ Spotify control sent")
    }

    private func sendToYouTube(keyCode: Int32) {
        switch keyCode {
        case NX_KEYTYPE_PLAY:
            NSLog("[YT] ▶️  Play/Pause → YouTube")
            youtubeController.togglePlayPause()
        case NX_KEYTYPE_NEXT, NX_KEYTYPE_FAST:
            NSLog("[YT] ⏭  Next track → YouTube")
            youtubeController.skipForward()
        case NX_KEYTYPE_PREVIOUS, NX_KEYTYPE_REWIND:
            NSLog("[YT] ⏮  Previous track → YouTube")
            youtubeController.skipBackward()
        default:
            NSLog("[YT] ❓ Unknown media key: \(keyCode)")
            return
        }

        lastSuccessTime = Date().timeIntervalSince1970
        NSLog("[YT] ✅ YouTube control sent")
    }

    deinit {
        youtubeCheckTimer?.invalidate()
        stopListening()
    }
}
