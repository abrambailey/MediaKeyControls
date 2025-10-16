import Cocoa
import ApplicationServices

class MediaKeyHandler {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isEnabled = true // Toggle for enabling/disabling capture

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
    }

    func toggle() {
        isEnabled.toggle()
        UserDefaults.standard.set(isEnabled, forKey: "mediaKeysEnabled")
        NSLog("[BC] Media key capture toggled: \(isEnabled)")
    }

    func getEnabled() -> Bool {
        return isEnabled
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

                    // Only handle if enabled
                    if !isEnabled {
                        NSLog("[BC] 🔇 Media key capture disabled, passing through")
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

        var action: String?

        switch keyCode {
        case NX_KEYTYPE_PLAY:
            NSLog("[BC] ▶️  Play/Pause triggered")
            action = "playPause"
        case NX_KEYTYPE_NEXT, NX_KEYTYPE_FAST:
            NSLog("[BC] ⏭  Next track triggered")
            action = "next"
        case NX_KEYTYPE_PREVIOUS, NX_KEYTYPE_REWIND:
            NSLog("[BC] ⏮  Previous track triggered")
            action = "previous"
        default:
            NSLog("[BC] ❓ Unknown media key: \(keyCode)")
            break
        }

        if let action = action {
            // Post distributed notification to native messaging host
            DistributedNotificationCenter.default().post(
                name: NSNotification.Name("com.bandcamp.controls.mediakey"),
                object: nil,
                userInfo: ["action": action]
            )
            NSLog("[BC] 📤 Posted notification for action: \(action)")
        }
    }

    deinit {
        stopListening()
    }
}
