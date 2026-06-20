import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let contentViewController = NSViewController()

        let label = NSTextField(labelWithString: "SoundSight is running.")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.setAccessibilityLabel("SoundSight is running")

        contentViewController.view = NSView()
        contentViewController.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentViewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentViewController.view.centerYAnchor)
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 240),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "SoundSight"
        window.contentViewController = contentViewController
        window.center()
        window.makeKeyAndOrderFront(nil)

        self.window = window
        NSApp.activate(ignoringOtherApps: true)

        NSSound.beep()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
