import Cocoa
import AppKit

class YouTubeController {

    // Check if Safari is running
    private func isSafariRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.Safari" }
    }

    // Check if any Chrome-based browser is running
    private func isChromeRunning() -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        let chromeBundleIds = [
            "com.google.Chrome",
            "org.chromium.Chromium",
            "com.brave.Browser"
        ]
        return runningApps.contains { app in
            chromeBundleIds.contains(app.bundleIdentifier ?? "")
        }
    }

    // JavaScript commands for YouTube player
    private let playPauseScript = """
(function() {
    var btn = document.querySelector('.ytp-play-button');
    if (btn) {
        btn.click();
        return 'dispatched';
    }
    return 'not found';
})();
"""

    private let skipForwardScript = """
(function() {
    var btn = document.querySelector('.ytp-next-button');
    if (btn && btn.offsetParent !== null) {
        btn.click();
        return 'dispatched next';
    }
    return 'next not available';
})();
"""

    private let skipBackwardScript = """
(function() {
    var btn = document.querySelector('.ytp-prev-button');
    if (btn && btn.offsetParent !== null) {
        btn.click();
        return 'dispatched prev';
    }
    // If no previous button, seek to beginning
    var video = document.querySelector('video');
    if (video) {
        video.currentTime = 0;
        return 'restarted video';
    }
    return 'prev not available';
})();
"""

    private let getPlayingStateScript = """
(function() {
    var video = document.querySelector('video');
    if (video) {
        return video.paused ? 'paused' : 'playing';
    }
    return 'not found';
})();
"""

    func togglePlayPause() {
        NSLog("[MC] ▶️ Executing play/pause on YouTube...")
        executeJavaScriptOnYouTube(script: playPauseScript)
    }

    func skipForward() {
        NSLog("[MC] ⏭ Executing skip forward on YouTube...")
        executeJavaScriptOnYouTube(script: skipForwardScript)
    }

    func skipBackward() {
        NSLog("[MC] ⏮ Executing skip backward on YouTube...")
        executeJavaScriptOnYouTube(script: skipBackwardScript)
    }

    func isYouTubePlaying() -> Bool {
        // Try Safari first - only if it's running
        if isSafariRunning() {
            if let state = executeSafariScript(script: getPlayingStateScript), state == "playing" {
                return true
            }
        }

        // Try Chrome/Chromium browsers - only if Chrome is running
        if isChromeRunning() {
            if let state = executeChromeScript(script: getPlayingStateScript), state == "playing" {
                return true
            }
        }

        return false
    }

    func hasYouTubeTabs() -> Bool {
        var hasTabs = false

        // Check Safari only if it's running
        if isSafariRunning() {
            hasTabs = hasTabs || checkSafariHasYouTube()
        }

        // Check Chrome only if it's running
        if isChromeRunning() {
            hasTabs = hasTabs || checkChromeHasYouTube()
        }

        return hasTabs
    }

    private func executeJavaScriptOnYouTube(script: String) {
        // Try Safari first - only if it's running
        if isSafariRunning() {
            if executeSafariScript(script: script) != nil {
                return
            }
        }

        // Try Chrome/Chromium browsers - only if Chrome is running
        if isChromeRunning() {
            if executeChromeScript(script: script) != nil {
                return
            }
        }

        NSLog("[MC] No YouTube tab found (no browsers running or no YouTube tabs)")
    }

    private func executeSafariScript(script: String) -> String? {
        NSLog("[MC] 🧭 Trying Safari...")

        let appleScript = """
        tell application "Safari"
            set found to false
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "youtube.com/watch" then
                        set result to (tell t to do JavaScript "\(script.replacingOccurrences(of: "\"", with: "\\\""))")
                        return result as text
                    end if
                end repeat
            end repeat
            return "not found"
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let result = scriptObject.executeAndReturnError(&error)
            if let err = error {
                NSLog("[MC] ❌ Safari error: \(err)")
                return nil
            }
            let resultStr = result.stringValue ?? "not found"
            if resultStr != "not found" {
                NSLog("[MC] ✅ Executed JavaScript on Safari successfully")
                return resultStr
            }
        }

        return nil
    }

    private func executeChromeScript(script: String) -> String? {
        let browsers = ["Google Chrome", "Chromium", "Brave Browser"]

        for browser in browsers {
            NSLog("[MC] 🌐 Trying \(browser)...")

            let appleScript = """
            tell application "\(browser)"
                set found to false
                repeat with w in windows
                    repeat with t in tabs of w
                        if URL of t contains "youtube.com/watch" then
                            set result to (execute t javascript "\(script.replacingOccurrences(of: "\"", with: "\\\""))")
                            return result as text
                        end if
                    end repeat
                end repeat
                return "not found"
            end tell
            """

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let result = scriptObject.executeAndReturnError(&error)
                if let err = error {
                    NSLog("[MC] \(browser) error: \(err)")
                    continue
                }
                let resultStr = result.stringValue ?? "not found"
                if resultStr != "not found" {
                    NSLog("[MC] ✅ Executed on \(browser)")
                    return resultStr
                }
            }
        }

        return nil
    }

    private func checkSafariHasYouTube() -> Bool {
        let appleScript = """
        tell application "Safari"
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "youtube.com/watch" then
                        return true
                    end if
                end repeat
            end repeat
            return false
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let result = scriptObject.executeAndReturnError(&error)
            return error == nil && result.booleanValue
        }
        return false
    }

    private func checkChromeHasYouTube() -> Bool {
        let browsers = ["Google Chrome", "Chromium", "Brave Browser"]

        for browser in browsers {
            let appleScript = """
            tell application "\(browser)"
                repeat with w in windows
                    repeat with t in tabs of w
                        if URL of t contains "youtube.com/watch" then
                            return true
                        end if
                    end repeat
                end repeat
                return false
            end tell
            """

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let result = scriptObject.executeAndReturnError(&error)
                if error == nil && result.booleanValue {
                    return true
                }
            }
        }

        return false
    }
}
