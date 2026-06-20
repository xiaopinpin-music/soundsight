import AppKit

struct DetectedApplication {
    let name: String
    let bundleIdentifier: String
    let processIdentifier: pid_t
}

enum AppDetector {
    static let universalControlBundleIdentifier = "com.fender.ucapp"

    static func findUniversalControl() -> DetectedApplication? {
        NSWorkspace.shared.runningApplications.first { application in
            application.bundleIdentifier?
                .caseInsensitiveCompare(
                    universalControlBundleIdentifier
                ) == .orderedSame
        }
        .map { application in
            DetectedApplication(
                name: application.localizedName ?? "Universal Control",
                bundleIdentifier:
                    application.bundleIdentifier
                    ?? universalControlBundleIdentifier,
                processIdentifier: application.processIdentifier
            )
        }
    }
}
