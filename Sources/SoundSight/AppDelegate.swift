import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private var permissionStatusLabel: NSTextField?
    private var universalControlStatusLabel: NSTextField?
    private var detectionTimer: Timer?
    private var lastDetectedProcessIdentifier: pid_t?
    private let speechSynthesizer = NSSpeechSynthesizer()

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMainWindow()
        updatePermissionStatus()
        AccessibilityPermission.requestIfNeeded()
        detectUniversalControl(announceChanges: false)
        startUniversalControlMonitoring()
    }

    private func buildMainWindow() {
        let viewController = NSViewController()
        let rootView = NSView()
        viewController.view = rootView

        let titleLabel = NSTextField(labelWithString: "SoundSight")
        titleLabel.font = NSFont.systemFont(ofSize: 24, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setAccessibilityLabel("SoundSight")

        let descriptionLabel = NSTextField(
            wrappingLabelWithString:
                "SoundSight inspects inaccessible application interfaces and presents useful information to VoiceOver."
        )
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.alignment = .center
        descriptionLabel.maximumNumberOfLines = 3

        let permissionStatusLabel = NSTextField(labelWithString: "")
        permissionStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        permissionStatusLabel.alignment = .center
        self.permissionStatusLabel = permissionStatusLabel

        let permissionButton = NSButton(
            title: "Check Accessibility Permission",
            target: self,
            action: #selector(checkPermission)
        )
        permissionButton.translatesAutoresizingMaskIntoConstraints = false
        permissionButton.bezelStyle = .rounded
        permissionButton.setAccessibilityLabel(
            "Check Accessibility Permission"
        )
        permissionButton.setAccessibilityHelp(
            "Checks whether SoundSight can inspect other applications."
        )

        let universalControlStatusLabel = NSTextField(labelWithString: "")
        universalControlStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        universalControlStatusLabel.alignment = .center
        universalControlStatusLabel.maximumNumberOfLines = 2
        self.universalControlStatusLabel = universalControlStatusLabel

        let detectButton = NSButton(
            title: "Detect Universal Control",
            target: self,
            action: #selector(manualDetection)
        )
        detectButton.translatesAutoresizingMaskIntoConstraints = false
        detectButton.bezelStyle = .rounded
        detectButton.setAccessibilityLabel("Detect Universal Control")
        detectButton.setAccessibilityHelp(
            "Checks whether PreSonus Universal Control is currently running."
        )

        rootView.addSubview(titleLabel)
        rootView.addSubview(descriptionLabel)
        rootView.addSubview(permissionStatusLabel)
        rootView.addSubview(permissionButton)
        rootView.addSubview(universalControlStatusLabel)
        rootView.addSubview(detectButton)

        let scanButton = NSButton(
            title: "Scan Universal Control Interface",
            target: self,
            action: #selector(scanUniversalControlInterface)
        )
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        scanButton.bezelStyle = .rounded
        scanButton.setAccessibilityLabel(
            "Scan Universal Control Interface"
        )
        scanButton.setAccessibilityHelp(
            "Scans the menu bar, windows, controls, values, and actions exposed by Fender Universal Control."
        )
        rootView.addSubview(scanButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(
                equalTo: rootView.topAnchor,
                constant: 28
            ),
            titleLabel.centerXAnchor.constraint(
                equalTo: rootView.centerXAnchor
            ),

            descriptionLabel.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor,
                constant: 18
            ),
            descriptionLabel.leadingAnchor.constraint(
                equalTo: rootView.leadingAnchor,
                constant: 35
            ),
            descriptionLabel.trailingAnchor.constraint(
                equalTo: rootView.trailingAnchor,
                constant: -35
            ),

            permissionStatusLabel.topAnchor.constraint(
                equalTo: descriptionLabel.bottomAnchor,
                constant: 20
            ),
            permissionStatusLabel.centerXAnchor.constraint(
                equalTo: rootView.centerXAnchor
            ),

            permissionButton.topAnchor.constraint(
                equalTo: permissionStatusLabel.bottomAnchor,
                constant: 14
            ),
            permissionButton.centerXAnchor.constraint(
                equalTo: rootView.centerXAnchor
            ),

            universalControlStatusLabel.topAnchor.constraint(
                equalTo: permissionButton.bottomAnchor,
                constant: 25
            ),
            universalControlStatusLabel.leadingAnchor.constraint(
                equalTo: rootView.leadingAnchor,
                constant: 35
            ),
            universalControlStatusLabel.trailingAnchor.constraint(
                equalTo: rootView.trailingAnchor,
                constant: -35
            ),

            detectButton.topAnchor.constraint(
                equalTo: universalControlStatusLabel.bottomAnchor,
                constant: 14
            ),
            detectButton.centerXAnchor.constraint(
                equalTo: rootView.centerXAnchor
            ),

            scanButton.topAnchor.constraint(
                equalTo: detectButton.bottomAnchor,
                constant: 16
            ),
            scanButton.centerXAnchor.constraint(
                equalTo: rootView.centerXAnchor
            )
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 450),
            styleMask: [
                .titled,
                .closable,
                .miniaturizable,
                .resizable
            ],
            backing: .buffered,
            defer: false
        )

        window.title = "SoundSight"
        window.contentViewController = viewController
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.window = window
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func checkPermission() {
        updatePermissionStatus()

        if !AccessibilityPermission.isTrusted {
            AccessibilityPermission.requestIfNeeded()
        }
    }

    @objc private func manualDetection() {
        if let application = AppDetector.findUniversalControl() {
            lastDetectedProcessIdentifier =
                application.processIdentifier

            let message =
                "Fender Universal Control detected. " +
                "Bundle identifier \(application.bundleIdentifier). " +
                "Process identifier \(application.processIdentifier)."

            universalControlStatusLabel?.stringValue = message
            universalControlStatusLabel?
                .setAccessibilityLabel(message)

            announce(
                "Fender Universal Control detected. " +
                "Ready to scan interface."
            )
        } else {
            lastDetectedProcessIdentifier = nil

            let message =
                "Fender Universal Control is not running."

            universalControlStatusLabel?.stringValue = message
            universalControlStatusLabel?
                .setAccessibilityLabel(message)

            announce(message)
        }
    }

    @objc private func scanUniversalControlInterface() {
        guard AccessibilityPermission.isTrusted else {
            announce(
                "Accessibility permission is required before scanning."
            )
            return
        }

        guard let application =
                AppDetector.findUniversalControl() else {
            announce(
                "Fender Universal Control is not running."
            )
            return
        }

        announce(
            "Scanning Universal Control interface."
        )

        do {
            let result = try AXScanner.scanUniversalControl(
                processIdentifier: application.processIdentifier
            )

            let message =
                "Scan complete. " +
                "\(result.nodeCount) elements inspected. " +
                "\(result.actionableCount) actionable elements found."

            universalControlStatusLabel?.stringValue =
                message + " Report saved."

            universalControlStatusLabel?
                .setAccessibilityLabel(
                    message + " Report saved."
                )

            announce(message)

            print(
                "[SoundSight] Scan report: " +
                result.reportURL.path
            )
        } catch {
            let message =
                "Scan failed. \(error.localizedDescription)"

            universalControlStatusLabel?.stringValue = message
            universalControlStatusLabel?
                .setAccessibilityLabel(message)

            announce(message)
            print("[SoundSight] \(message)")
        }
    }

    private func updatePermissionStatus() {
        let granted = AccessibilityPermission.isTrusted

        let message = granted
            ? "Accessibility permission granted."
            : "Accessibility permission not granted."

        permissionStatusLabel?.stringValue = message
        permissionStatusLabel?.setAccessibilityLabel(message)

        announce(message)
    }

    private func startUniversalControlMonitoring() {
        detectionTimer?.invalidate()

        detectionTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.detectUniversalControl(announceChanges: true)
            }
        }
    }

    private func detectUniversalControl(announceChanges: Bool) {
        if let application = AppDetector.findUniversalControl() {
            let processIdentifier = application.processIdentifier

            let message =
                "\(application.name) detected. Process identifier \(processIdentifier)."

            universalControlStatusLabel?.stringValue = message
            universalControlStatusLabel?.setAccessibilityLabel(message)

            if announceChanges &&
                lastDetectedProcessIdentifier != processIdentifier {
                announce(
                    "Universal Control detected. Ready to scan interface."
                )
            }

            lastDetectedProcessIdentifier = processIdentifier
        } else {
            let wasPreviouslyDetected =
                lastDetectedProcessIdentifier != nil

            let message = "Universal Control is not running."

            universalControlStatusLabel?.stringValue = message
            universalControlStatusLabel?.setAccessibilityLabel(message)

            if announceChanges && wasPreviouslyDetected {
                announce("Universal Control closed.")
            }

            lastDetectedProcessIdentifier = nil
        }
    }

    private func announce(_ message: String) {
        print("[SoundSight] \(message)")

        if let element = universalControlStatusLabel
            ?? permissionStatusLabel {
            NSAccessibility.post(
                element: element,
                notification: .announcementRequested,
                userInfo: [
                    .announcement: message,
                    .priority:
                        NSAccessibilityPriorityLevel.high.rawValue
                ]
            )
        }

        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking()
        }

        speechSynthesizer.startSpeaking(message)
    }

    func applicationWillTerminate(_ notification: Notification) {
        detectionTimer?.invalidate()
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }
}
