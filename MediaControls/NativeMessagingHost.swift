import Foundation

// Native Messaging Host for Chrome Extension
// This binary is launched by Chrome and communicates via stdin/stdout
// It also listens for distributed notifications from the main app

class NativeMessagingHost {
    private let stdin = FileHandle.standardInput
    private let stdout = FileHandle.standardOutput
    private let stderr = FileHandle.standardError
    private var hasBandcampTabs = false

    func run() {
        logToFile("Native messaging host started")

        // Listen for distributed notifications from main app
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleMediaKeyNotification(_:)),
            name: NSNotification.Name("com.mediakeycontrols.mediakey"),
            object: nil
        )

        logToFile("Listening for media key notifications...")

        // Listen for responses from Chrome in a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.readFromChrome()
        }

        // Keep the run loop alive to receive notifications
        RunLoop.main.run()
    }

    func readFromChrome() {
        while true {
            // Read 4-byte length prefix
            let lengthData = stdin.readData(ofLength: 4)
            if lengthData.count != 4 { break }

            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }

            // Read JSON message
            let messageData = stdin.readData(ofLength: Int(length))
            if let json = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] {
                logToFile("Received from Chrome: \(json)")

                // Handle tab state updates
                if let type = json["type"] as? String, type == "tabState" {
                    let hasTabs = json["hasTabs"] as? Bool ?? false
                    let isPlaying = json["isPlaying"] as? Bool ?? false
                    let activeTabIsMedia = json["activeTabIsMedia"] as? Bool ?? false
                    let activeTabService = json["activeTabService"] as? String

                    hasBandcampTabs = hasTabs

                    // Notify main app about tab state
                    var userInfo: [String: Any] = [
                        "hasTabs": hasTabs,
                        "isPlaying": isPlaying,
                        "activeTabIsMedia": activeTabIsMedia
                    ]
                    if let service = activeTabService {
                        userInfo["activeTabService"] = service
                    }

                    DistributedNotificationCenter.default().post(
                        name: NSNotification.Name("com.mediakeycontrols.tabstate"),
                        object: nil,
                        userInfo: userInfo
                    )

                    logToFile("Notified main app: hasTabs=\(hasTabs), isPlaying=\(isPlaying), activeTabIsMedia=\(activeTabIsMedia), activeTabService=\(activeTabService ?? "nil")")
                }
                // Handle legacy success responses
                else if let success = json["success"] as? Bool {
                    hasBandcampTabs = success

                    // Notify main app about successful control
                    DistributedNotificationCenter.default().post(
                        name: NSNotification.Name("com.mediakeycontrols.tabstate"),
                        object: nil,
                        userInfo: [
                            "hasTabs": hasBandcampTabs,
                            "success": success
                        ]
                    )
                }
            }
        }
    }

    @objc func handleMediaKeyNotification(_ notification: Notification) {
        guard let action = notification.userInfo?["action"] as? String else {
            logToFile("Received notification without action")
            return
        }

        logToFile("Received notification: \(action)")
        sendMessageToChrome(action: action)
    }

    func sendMessageToChrome(action: String) {
        let message: [String: String] = ["action": action]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            logToFile("Failed to serialize message")
            return
        }

        logToFile("Sending to Chrome: \(jsonString)")

        // Native messaging format: 4-byte length prefix (little-endian) + JSON message
        let length = UInt32(jsonData.count)
        var lengthBytes = length.littleEndian

        let lengthData = Data(bytes: &lengthBytes, count: 4)
        stdout.write(lengthData)
        stdout.write(jsonData)

        // Flush to ensure message is sent immediately
        if #available(macOS 10.15.4, *) {
            try? stdout.synchronize()
        }

        logToFile("Message sent to Chrome")
    }

    func logToFile(_ message: String) {
        let logPath = "/tmp/bandcamp_native_host.log"
        let timestamp = Date().ISO8601Format()
        let logMessage = "[\(timestamp)] \(message)\n"

        if let data = logMessage.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }
}

// Entry point
let host = NativeMessagingHost()
host.run()
