import AppKit
import ApplicationServices

enum AccessibilityPermission {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static func requestIfNeeded() {
        guard !isTrusted else {
            return
        }

        let options: NSDictionary = [
            "AXTrustedCheckOptionPrompt": true
        ]

        _ = AXIsProcessTrustedWithOptions(options)
    }
}
