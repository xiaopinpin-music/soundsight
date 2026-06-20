import AppKit
import ApplicationServices
import Foundation

struct AXScanResult {
    let nodeCount: Int
    let actionableCount: Int
    let reportURL: URL
}

enum AXScanner {
    private static let maximumDepth = 20
    private static let maximumNodes = 10_000

    static func scanUniversalControl(
        processIdentifier: pid_t
    ) throws -> AXScanResult {
        let applicationElement = AXUIElementCreateApplication(
            processIdentifier
        )

        var lines: [String] = []
        var visited: Set<UInt> = []
        var nodeCount = 0
        var actionableCount = 0

        lines.append("SoundSight Universal Control Accessibility Scan")
        lines.append("Process identifier: \(processIdentifier)")
        lines.append("Date: \(ISO8601DateFormatter().string(from: Date()))")
        lines.append("")

        scanElement(
            applicationElement,
            label: "Application",
            depth: 0,
            lines: &lines,
            visited: &visited,
            nodeCount: &nodeCount,
            actionableCount: &actionableCount
        )

        if let menuBar = copyElementAttribute(
            applicationElement,
            attribute: "AXMenuBar"
        ) {
            lines.append("")
            lines.append("===== MENU BAR =====")

            scanElement(
                menuBar,
                label: "MenuBar",
                depth: 0,
                lines: &lines,
                visited: &visited,
                nodeCount: &nodeCount,
                actionableCount: &actionableCount
            )
        } else {
            lines.append("")
            lines.append("===== MENU BAR NOT EXPOSED =====")
        }

        if let windows = copyElementArrayAttribute(
            applicationElement,
            attribute: "AXWindows"
        ) {
            lines.append("")
            lines.append("===== WINDOWS: \(windows.count) =====")

            for (index, window) in windows.enumerated() {
                scanElement(
                    window,
                    label: "Window \(index + 1)",
                    depth: 0,
                    lines: &lines,
                    visited: &visited,
                    nodeCount: &nodeCount,
                    actionableCount: &actionableCount
                )
            }
        } else {
            lines.append("")
            lines.append("===== WINDOWS NOT EXPOSED =====")
        }

        lines.append("")
        lines.append("===== SUMMARY =====")
        lines.append("Nodes inspected: \(nodeCount)")
        lines.append("Actionable nodes: \(actionableCount)")

        let fileManager = FileManager.default
        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let scansDirectory = applicationSupport
            .appendingPathComponent("SoundSight", isDirectory: true)
            .appendingPathComponent("Scans", isDirectory: true)

        try fileManager.createDirectory(
            at: scansDirectory,
            withIntermediateDirectories: true
        )

        let reportURL = scansDirectory.appendingPathComponent(
            "Universal-Control-AX-Scan.txt"
        )

        try lines.joined(separator: "\n").write(
            to: reportURL,
            atomically: true,
            encoding: .utf8
        )

        return AXScanResult(
            nodeCount: nodeCount,
            actionableCount: actionableCount,
            reportURL: reportURL
        )
    }

    private static func scanElement(
        _ element: AXUIElement,
        label: String,
        depth: Int,
        lines: inout [String],
        visited: inout Set<UInt>,
        nodeCount: inout Int,
        actionableCount: inout Int
    ) {
        guard depth <= maximumDepth else {
            lines.append(
                "\(indent(depth))\(label): maximum depth reached"
            )
            return
        }

        guard nodeCount < maximumNodes else {
            lines.append(
                "\(indent(depth))\(label): maximum node count reached"
            )
            return
        }

        let identity = UInt(bitPattern: Unmanaged.passUnretained(
            element
        ).toOpaque())

        guard !visited.contains(identity) else {
            lines.append(
                "\(indent(depth))\(label): already visited"
            )
            return
        }

        visited.insert(identity)
        nodeCount += 1

        let role = stringAttribute(element, "AXRole") ?? "Unknown"
        let subrole = stringAttribute(element, "AXSubrole")
        let title = stringAttribute(element, "AXTitle")
        let description = stringAttribute(
            element,
            "AXDescription"
        )
        let help = stringAttribute(element, "AXHelp")
        let identifier = stringAttribute(element, "AXIdentifier")
        let value = readableAttribute(element, "AXValue")
        let enabled = readableAttribute(element, "AXEnabled")
        let position = readableAttribute(element, "AXPosition")
        let size = readableAttribute(element, "AXSize")
        let actions = actionNames(element)

        if !actions.isEmpty {
            actionableCount += 1
        }

        lines.append("\(indent(depth))\(label)")
        lines.append("\(indent(depth + 1))Role: \(role)")

        appendIfPresent(
            "Subrole",
            subrole,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Title",
            title,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Description",
            description,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Help",
            help,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Identifier",
            identifier,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Value",
            value,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Enabled",
            enabled,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Position",
            position,
            depth: depth + 1,
            lines: &lines
        )
        appendIfPresent(
            "Size",
            size,
            depth: depth + 1,
            lines: &lines
        )

        if !actions.isEmpty {
            lines.append(
                "\(indent(depth + 1))Actions: " +
                actions.joined(separator: ", ")
            )
        }

        var children = copyElementArrayAttribute(
            element,
            attribute: "AXChildren"
        ) ?? []

        if children.isEmpty {
            children = copyElementArrayAttribute(
                element,
                attribute: "AXVisibleChildren"
            ) ?? []
        }

        if !children.isEmpty {
            lines.append(
                "\(indent(depth + 1))Children: \(children.count)"
            )
        }

        for (index, child) in children.enumerated() {
            scanElement(
                child,
                label: "Child \(index + 1)",
                depth: depth + 1,
                lines: &lines,
                visited: &visited,
                nodeCount: &nodeCount,
                actionableCount: &actionableCount
            )
        }
    }

    private static func copyAttribute(
        _ element: AXUIElement,
        attribute: String
    ) -> CFTypeRef? {
        var value: CFTypeRef?

        let error = AXUIElementCopyAttributeValue(
            element,
            attribute as CFString,
            &value
        )

        guard error == .success else {
            return nil
        }

        return value
    }

    private static func copyElementAttribute(
        _ element: AXUIElement,
        attribute: String
    ) -> AXUIElement? {
        guard let value = copyAttribute(
            element,
            attribute: attribute
        ) else {
            return nil
        }

        guard CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }

        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private static func copyElementArrayAttribute(
        _ element: AXUIElement,
        attribute: String
    ) -> [AXUIElement]? {
        guard let value = copyAttribute(
            element,
            attribute: attribute
        ) else {
            return nil
        }

        guard CFGetTypeID(value) == CFArrayGetTypeID() else {
            return nil
        }

        let array = unsafeBitCast(value, to: CFArray.self)
        var elements: [AXUIElement] = []

        for index in 0..<CFArrayGetCount(array) {
            let rawValue = CFArrayGetValueAtIndex(array, index)
            let object = unsafeBitCast(
                rawValue,
                to: CFTypeRef.self
            )

            if CFGetTypeID(object) == AXUIElementGetTypeID() {
                elements.append(
                    unsafeBitCast(object, to: AXUIElement.self)
                )
            }
        }

        return elements
    }

    private static func stringAttribute(
        _ element: AXUIElement,
        _ attribute: String
    ) -> String? {
        guard let value = copyAttribute(
            element,
            attribute: attribute
        ) else {
            return nil
        }

        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as? String
        }

        return nil
    }

    private static func readableAttribute(
        _ element: AXUIElement,
        _ attribute: String
    ) -> String? {
        guard let value = copyAttribute(
            element,
            attribute: attribute
        ) else {
            return nil
        }

        if CFGetTypeID(value) == CFStringGetTypeID() {
            return value as? String
        }

        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            let booleanValue = unsafeBitCast(
                value,
                to: CFBoolean.self
            )

            return CFBooleanGetValue(booleanValue)
                ? "true"
                : "false"
        }

        if CFGetTypeID(value) == CFNumberGetTypeID() {
            return String(describing: value)
        }

        if CFGetTypeID(value) == AXValueGetTypeID() {
            return describeAXValue(
                unsafeBitCast(value, to: AXValue.self)
            )
        }

        return String(describing: value)
    }

    private static func describeAXValue(
        _ value: AXValue
    ) -> String {
        switch AXValueGetType(value) {
        case .cgPoint:
            var point = CGPoint.zero
            if AXValueGetValue(value, .cgPoint, &point) {
                return "x \(point.x), y \(point.y)"
            }

        case .cgSize:
            var size = CGSize.zero
            if AXValueGetValue(value, .cgSize, &size) {
                return "width \(size.width), height \(size.height)"
            }

        case .cgRect:
            var rect = CGRect.zero
            if AXValueGetValue(value, .cgRect, &rect) {
                return
                    "x \(rect.origin.x), y \(rect.origin.y), " +
                    "width \(rect.size.width), " +
                    "height \(rect.size.height)"
            }

        case .cfRange:
            var range = CFRange()
            if AXValueGetValue(value, .cfRange, &range) {
                return
                    "location \(range.location), " +
                    "length \(range.length)"
            }

        case .axError:
            var error = AXError.success
            if AXValueGetValue(value, .axError, &error) {
                return "AXError \(error.rawValue)"
            }

        case .illegal:
            return "illegal AX value"

        @unknown default:
            return "unknown AX value"
        }

        return "unreadable AX value"
    }

    private static func actionNames(
        _ element: AXUIElement
    ) -> [String] {
        var names: CFArray?

        let error = AXUIElementCopyActionNames(
            element,
            &names
        )

        guard error == .success,
              let names else {
            return []
        }

        return names as? [String] ?? []
    }

    private static func appendIfPresent(
        _ name: String,
        _ value: String?,
        depth: Int,
        lines: inout [String]
    ) {
        guard let value,
              !value.isEmpty else {
            return
        }

        lines.append("\(indent(depth))\(name): \(value)")
    }

    private static func indent(_ depth: Int) -> String {
        String(repeating: "  ", count: depth)
    }
}
