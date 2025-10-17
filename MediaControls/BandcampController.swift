import Cocoa
import AppKit

class BandcampController {

    // JavaScript commands for Bandcamp player - use MouseEvent instead of click()
    private let playPauseScript = """
(function() {
    var btn = document.querySelector('.playbutton');
    if (btn) {
        var evt = new MouseEvent('click', { bubbles: true, cancelable: true, view: window });
        btn.dispatchEvent(evt);
        return 'dispatched';
    }
    return 'not found';
})();
"""

    private let skipForwardScript = """
(function() {
    var btn = document.querySelector('.nextbutton');
    if (btn && !btn.classList.contains('hiddenelem')) {
        var evt = new MouseEvent('click', { bubbles: true, cancelable: true, view: window });
        btn.dispatchEvent(evt);
        return 'dispatched next';
    }
    return 'next not available';
})();
"""

    private let skipBackwardScript = """
(function() {
    var btn = document.querySelector('.prevbutton');
    if (btn && !btn.classList.contains('hiddenelem')) {
        var evt = new MouseEvent('click', { bubbles: true, cancelable: true, view: window });
        btn.dispatchEvent(evt);
        return 'dispatched prev';
    }
    // Fallback: restart current track by clicking beginning of progress bar
    var bar = document.querySelector('.progbar_empty');
    if (bar) {
        var r = bar.getBoundingClientRect();
        var evt = new MouseEvent('click', { view: window, bubbles: true, cancelable: true, clientX: r.left + 5, clientY: r.top + 5 });
        bar.dispatchEvent(evt);
        return 'restarted track';
    }
    return 'prev not available';
})();
"""

    func togglePlayPause() {
        NSLog("[MC] ▶️ Executing play/pause on Bandcamp...")
        executeJavaScriptOnBandcamp(script: playPauseScript)
    }

    func skipForward() {
        NSLog("[MC] ⏭ Executing skip forward on Bandcamp...")
        executeJavaScriptOnBandcamp(script: skipForwardScript)
    }

    func skipBackward() {
        NSLog("[MC] ⏮ Executing skip backward on Bandcamp...")
        executeJavaScriptOnBandcamp(script: skipBackwardScript)
    }

    private func executeJavaScriptOnBandcamp(script: String) {
        // Try Safari first
        if executeSafariScript(script: script) {
            return
        }

        // Try Chrome/Chromium browsers
        if executeChromeScript(script: script) {
            return
        }

        print("No Bandcamp tab found in Safari or Chrome")
    }

    private func executeSafariScript(script: String) -> Bool {
        NSLog("[MC] 🧭 Trying Safari with script: \(script)")

        let appleScript = """
        tell application "Safari"
            set found to false
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "bandcamp.com" then
                        tell t to do JavaScript "\(script.replacingOccurrences(of: "\"", with: "\\\""))"
                        set found to true
                        exit repeat
                    end if
                end repeat
                if found then exit repeat
            end repeat
            return found
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let result = scriptObject.executeAndReturnError(&error)
            if let err = error {
                NSLog("[MC] ❌ Safari error: \(err)")
            }
            if error == nil && result.booleanValue {
                NSLog("[MC] ✅ Executed JavaScript on Safari successfully")
                return true
            } else {
                NSLog("[MC] ❌ Safari script returned false or had error")
            }
        } else {
            NSLog("[MC] ❌ Failed to create AppleScript object")
        }

        NSLog("[MC] ❌ Safari: No Bandcamp tab found")
        return false
    }

    private func executeChromeScript(script: String) -> Bool {
        let browsers = ["Google Chrome", "Chromium", "Brave Browser"]

        for browser in browsers {
            NSLog("[MC] 🌐 Trying \(browser)...")

            let appleScript = """
            tell application "\(browser)"
                set found to false
                repeat with w in windows
                    repeat with t in tabs of w
                        if URL of t contains "bandcamp.com" then
                            execute t javascript "\(script.replacingOccurrences(of: "\"", with: "\\\""))"
                            set found to true
                            exit repeat
                        end if
                    end repeat
                    if found then exit repeat
                end repeat
                return found
            end tell
            """

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: appleScript) {
                let result = scriptObject.executeAndReturnError(&error)
                if let err = error {
                    NSLog("[MC] \(browser) error: \(err)")
                }
                if error == nil && result.booleanValue {
                    NSLog("[MC] ✅ Executed on \(browser)")
                    return true
                }
            }
        }

        NSLog("[MC] ❌ Chrome-based browsers: No Bandcamp tab found")
        return false
    }
}
