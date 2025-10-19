import SwiftUI
import ApplicationServices
import ServiceManagement

@main
struct MediaControlsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var mediaKeyHandler: MediaKeyHandler?
    var bandcampController: BandcampController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[MC] 🎵 MediaKey Controls starting up...")

        // Create menu bar item
        setupMenuBar()

        // Initialize controllers
        bandcampController = BandcampController()
        mediaKeyHandler = MediaKeyHandler()

        // Request accessibility permissions (this will show system dialog if needed)
        let hasPermission = checkAccessibilityPermissions()
        NSLog("[MC] Accessibility permission status: \(hasPermission)")

        if !hasPermission {
            NSLog("[MC] ⚠️ Missing Accessibility permissions - system dialog shown")

            // Check again after a delay in case user enables it (without re-prompting)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                if self?.checkAccessibilityPermissions(prompt: false) == true {
                    NSLog("[MC] ✅ Permissions granted! Starting listener with retry...")
                    self?.startListenerWithRetry()
                } else {
                    NSLog("[MC] ⚠️ Still no permissions. Use 'Check Permissions' menu to restart.")
                }
            }
        } else {
            // Permissions already granted - start immediately with retry logic
            NSLog("[MC] Permissions already granted, starting listener with retry...")
            startListenerWithRetry()
        }

        NSLog("[MC] MediaKey Controls ready!")
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "♫"
            button.font = NSFont.systemFont(ofSize: 16)
        }

        updateMenu()
    }

    func updateMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "MediaKey Controls", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Add enable/disable toggle
        let isEnabled = mediaKeyHandler?.getEnabled() ?? true
        let toggleTitle = isEnabled ? "✓ Media Keys Enabled" : "Media Keys Disabled"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleMediaKeys), keyEquivalent: "e")
        menu.addItem(toggleItem)
        menu.addItem(NSMenuItem.separator())

        // Add start at login toggle
        let startsAtLogin = isStartAtLoginEnabled()
        let loginTitle = startsAtLogin ? "✓ Start at Login" : "Start at Login"
        let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleStartAtLogin), keyEquivalent: "")
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())

        // Add test buttons
        menu.addItem(NSMenuItem(title: "Test Play/Pause", action: #selector(testPlayPause), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Test Next Track", action: #selector(testNext), keyEquivalent: "n"))
        menu.addItem(NSMenuItem(title: "Test Previous Track", action: #selector(testPrevious), keyEquivalent: "b"))
        menu.addItem(NSMenuItem.separator())

        // Add permission check
        menu.addItem(NSMenuItem(title: "Check Permissions", action: #selector(recheckPermissions), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc func toggleMediaKeys() {
        mediaKeyHandler?.toggle()
        let isEnabled = mediaKeyHandler?.getEnabled() ?? true
        NSLog("[MC] Media keys toggled to: \(isEnabled)")

        // Update menu to reflect new state
        updateMenu()

        // Show notification
        let alert = NSAlert()
        alert.messageText = isEnabled ? "Media Keys Enabled" : "Media Keys Disabled"
        alert.informativeText = isEnabled
            ? "Media keys will control Bandcamp, YouTube, and Spotify"
            : "Media keys will pass through to other apps"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func testPlayPause() {
        NSLog("[MC] Manual test: Play/Pause")
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.mediakeycontrols.mediakey"),
            object: nil,
            userInfo: ["action": "playPause"]
        )
    }

    @objc func testNext() {
        NSLog("[MC] Manual test: Next track")
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.mediakeycontrols.mediakey"),
            object: nil,
            userInfo: ["action": "next"]
        )
    }

    @objc func testPrevious() {
        NSLog("[MC] Manual test: Previous track")
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.mediakeycontrols.mediakey"),
            object: nil,
            userInfo: ["action": "previous"]
        )
    }

    func startListenerWithRetry(attempt: Int = 1, maxAttempts: Int = 3) {
        NSLog("[MC] Starting listener (attempt \(attempt)/\(maxAttempts))...")

        mediaKeyHandler?.stopListening()
        mediaKeyHandler?.startListening()

        // Retry a few times with increasing delays to ensure permissions have propagated
        if attempt < maxAttempts {
            let delay = Double(attempt) * 1.0  // 1s, 2s, 3s delays
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.startListenerWithRetry(attempt: attempt + 1, maxAttempts: maxAttempts)
            }
        } else {
            NSLog("[MC] ✅ Listener start attempts complete!")
        }
    }

    @objc func recheckPermissions() {
        NSLog("[MC] Manually rechecking permissions...")
        let wasGranted = checkAccessibilityPermissions()

        if wasGranted {
            NSLog("[MC] ✅ Permissions OK! Restarting listener...")
            mediaKeyHandler?.stopListening()
            mediaKeyHandler?.startListening()

            let alert = NSAlert()
            alert.messageText = "Permissions OK!"
            alert.informativeText = "Media key listener has been restarted. Try pressing F8!"
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            NSLog("[MC] ❌ Still no permissions - system dialog will appear")
            // System dialog already shown by checkAccessibilityPermissions
        }
    }

    @objc func toggleStartAtLogin() {
        if isStartAtLoginEnabled() {
            disableStartAtLogin()
        } else {
            enableStartAtLogin()
        }
        updateMenu()
    }

    func isStartAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older macOS versions, check UserDefaults as fallback
            return UserDefaults.standard.bool(forKey: "startAtLogin")
        }
    }

    func enableStartAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.register()
                NSLog("[MC] ✅ Start at login enabled")

                let alert = NSAlert()
                alert.messageText = "Start at Login Enabled"
                alert.informativeText = "MediaKey Controls will now start automatically when you log in."
                alert.alertStyle = .informational
                alert.runModal()
            } catch {
                NSLog("[MC] ❌ Failed to enable start at login: \(error)")

                let alert = NSAlert()
                alert.messageText = "Failed to Enable"
                alert.informativeText = "Could not enable start at login: \(error.localizedDescription)"
                alert.alertStyle = .warning
                alert.runModal()
            }
        } else {
            UserDefaults.standard.set(true, forKey: "startAtLogin")
            NSLog("[MC] ⚠️ Start at login saved to preferences (requires manual setup on macOS < 13)")
        }
    }

    func disableStartAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                try SMAppService.mainApp.unregister()
                NSLog("[MC] ✅ Start at login disabled")

                let alert = NSAlert()
                alert.messageText = "Start at Login Disabled"
                alert.informativeText = "MediaKey Controls will no longer start automatically."
                alert.alertStyle = .informational
                alert.runModal()
            } catch {
                NSLog("[MC] ❌ Failed to disable start at login: \(error)")
            }
        } else {
            UserDefaults.standard.set(false, forKey: "startAtLogin")
            NSLog("[MC] ⚠️ Start at login disabled in preferences")
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func checkAccessibilityPermissions(prompt: Bool = true) -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        let trusted = AXIsProcessTrustedWithOptions(options)
        NSLog("[MC] Accessibility check result: \(trusted)")
        return trusted
    }

    func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "This app needs accessibility permissions to capture media key events. Please enable it in System Settings > Privacy & Security > Accessibility."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Later")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
