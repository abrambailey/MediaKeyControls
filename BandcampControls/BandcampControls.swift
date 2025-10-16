import SwiftUI
import ApplicationServices

@main
struct BandcampControlsApp: App {
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
        NSLog("[BC] 🎵 BandcampControls starting up...")

        // Create menu bar item
        setupMenuBar()

        // Initialize controllers
        bandcampController = BandcampController()
        mediaKeyHandler = MediaKeyHandler()

        // Request accessibility permissions (this will show system dialog if needed)
        let hasPermission = checkAccessibilityPermissions()
        NSLog("[BC] Accessibility permission status: \(hasPermission)")

        if !hasPermission {
            NSLog("[BC] ⚠️ Missing Accessibility permissions - system dialog shown")

            // Check again after a delay in case user enables it
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.checkAccessibilityPermissions() == true {
                    NSLog("[BC] ✅ Permissions granted! Starting listener...")
                    self?.mediaKeyHandler?.startListening()
                } else {
                    NSLog("[BC] ⚠️ Still no permissions. Use 'Check Permissions' menu to restart.")
                }
            }
        } else {
            // Start listening for media keys
            NSLog("[BC] Starting media key listener...")
            mediaKeyHandler?.startListening()
        }

        NSLog("[BC] BandcampControls ready!")
    }

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Bandcamp Controls")
        }

        updateMenu()
    }

    func updateMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Bandcamp Controls", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        // Add enable/disable toggle
        let isEnabled = mediaKeyHandler?.getEnabled() ?? true
        let toggleTitle = isEnabled ? "✓ Media Keys Enabled" : "Media Keys Disabled"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleMediaKeys), keyEquivalent: "e")
        menu.addItem(toggleItem)
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
        NSLog("[BC] Media keys toggled to: \(isEnabled)")

        // Update menu to reflect new state
        updateMenu()

        // Show notification
        let alert = NSAlert()
        alert.messageText = isEnabled ? "Media Keys Enabled" : "Media Keys Disabled"
        alert.informativeText = isEnabled
            ? "Media keys will control Bandcamp"
            : "Media keys will pass through to other apps (Spotify, etc.)"
        alert.alertStyle = .informational
        alert.runModal()
    }

    @objc func testPlayPause() {
        NSLog("[BC] Manual test: Play/Pause")
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.bandcamp.controls.mediakey"),
            object: nil,
            userInfo: ["action": "playPause"]
        )
    }

    @objc func testNext() {
        NSLog("[BC] Manual test: Next track")
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.bandcamp.controls.mediakey"),
            object: nil,
            userInfo: ["action": "next"]
        )
    }

    @objc func testPrevious() {
        NSLog("[BC] Manual test: Previous track")
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.bandcamp.controls.mediakey"),
            object: nil,
            userInfo: ["action": "previous"]
        )
    }

    @objc func recheckPermissions() {
        NSLog("[BC] Manually rechecking permissions...")
        let wasGranted = checkAccessibilityPermissions()

        if wasGranted {
            NSLog("[BC] ✅ Permissions OK! Restarting listener...")
            mediaKeyHandler?.stopListening()
            mediaKeyHandler?.startListening()

            let alert = NSAlert()
            alert.messageText = "Permissions OK!"
            alert.informativeText = "Media key listener has been restarted. Try pressing F8 to control Bandcamp!"
            alert.alertStyle = .informational
            alert.runModal()
        } else {
            NSLog("[BC] ❌ Still no permissions - system dialog will appear")
            // System dialog already shown by checkAccessibilityPermissions
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }

    func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options)
        NSLog("[BC] Accessibility check result: \(trusted)")
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
