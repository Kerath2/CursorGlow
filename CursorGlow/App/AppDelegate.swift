import AppKit
import ApplicationServices
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let overlayManager = OverlayWindowManager()
    private let mouseTracker = MouseTracker()
    private let clickDetector = ClickDetector()
    private let idleTimer = IdleTimer()
    private let screenObserver = ScreenObserver()
    private let hotkeyManager = KeyboardShortcutManager()
    private let settings = CursorSettings.shared
    private var cancellables = Set<AnyCancellable>()
    private var cursorCheckTimer: Timer?
    private var lastDetectedCursorType: DetectedCursorType = .normal
    private var handCursorData: Data?
    private var iBeamCursorData: Data?
    private var iBeamVerticalData: Data?

    private enum DetectedCursorType {
        case normal, hand, iBeam
    }

    // Status bar
    private var statusItem: NSStatusItem!
    private var toggleMenuItem: NSMenuItem!
    private var colorPopover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupOverlay()
        setupMouseTracking()
        setupClickDetection()
        setupIdleTimer()
        setupScreenObserver()
        setupHotkey()
        setupCursorColorDetection()
        observeActiveState()
    }

    func applicationWillTerminate(_ notification: Notification) {
        mouseTracker.stop()
        clickDetector.stop()
        idleTimer.stop()
        screenObserver.stop()
        hotkeyManager.unregister()
        cursorCheckTimer?.invalidate()
        overlayManager.closeAll()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow.rays", accessibilityDescription: "CursorGlow")
            button.image?.size = NSSize(width: 18, height: 18)
            button.image?.isTemplate = true
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        toggleMenuItem = NSMenuItem(title: settings.isActive ? "Highlight: On" : "Highlight: Off", action: #selector(toggleHighlight), keyEquivalent: "h")
        toggleMenuItem.keyEquivalentModifierMask = [.command, .shift]
        toggleMenuItem.target = self
        menu.addItem(toggleMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Colors submenu
        let colorsMenu = NSMenu()

        let highlightColorItem = NSMenuItem(title: "Highlight Color", action: nil, keyEquivalent: "")
        let highlightColorView = ColorMenuItemView(
            title: "Highlight",
            color: settings.highlightColor
        ) { [weak self] newColor in
            self?.settings.highlightColor = newColor
        }
        highlightColorItem.view = highlightColorView
        colorsMenu.addItem(highlightColorItem)

        let leftClickItem = NSMenuItem(title: "Left Click Color", action: nil, keyEquivalent: "")
        let leftClickView = ColorMenuItemView(
            title: "Left Click",
            color: settings.leftClickColor
        ) { [weak self] newColor in
            self?.settings.leftClickColor = newColor
        }
        leftClickItem.view = leftClickView
        colorsMenu.addItem(leftClickItem)

        let rightClickItem = NSMenuItem(title: "Right Click Color", action: nil, keyEquivalent: "")
        let rightClickView = ColorMenuItemView(
            title: "Right Click",
            color: settings.rightClickColor
        ) { [weak self] newColor in
            self?.settings.rightClickColor = newColor
        }
        rightClickItem.view = rightClickView
        colorsMenu.addItem(rightClickItem)

        colorsMenu.addItem(NSMenuItem.separator())

        let handItem = NSMenuItem(title: "Hand Cursor", action: nil, keyEquivalent: "")
        let handView = ColorMenuItemView(
            title: "Hand (links)",
            color: settings.handCursorColor
        ) { [weak self] newColor in
            self?.settings.handCursorColor = newColor
        }
        handItem.view = handView
        colorsMenu.addItem(handItem)

        let iBeamItem = NSMenuItem(title: "Text Cursor", action: nil, keyEquivalent: "")
        let iBeamView = ColorMenuItemView(
            title: "Text (I-beam)",
            color: settings.iBeamCursorColor
        ) { [weak self] newColor in
            self?.settings.iBeamCursorColor = newColor
        }
        iBeamItem.view = iBeamView
        colorsMenu.addItem(iBeamItem)

        let colorsSubmenu = NSMenuItem(title: "Colors", action: nil, keyEquivalent: "")
        colorsSubmenu.submenu = colorsMenu
        menu.addItem(colorsSubmenu)

        menu.addItem(NSMenuItem.separator())

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = settings.launchAtLogin ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit CursorGlow", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func toggleHighlight() {
        settings.isActive.toggle()
    }

    @objc private func toggleLaunchAtLogin() {
        settings.launchAtLogin.toggle()
    }

    @objc private func openSettings() {
        // Defer to let the status bar menu fully dismiss first
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)

            if #available(macOS 14.0, *) {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } else {
                NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            }

            self.waitForSettingsWindow(attempts: 10)
        }
    }

    private var settingsWindowObserver: NSObjectProtocol?

    private func waitForSettingsWindow(attempts: Int) {
        guard attempts > 0 else {
            NSApp.setActivationPolicy(.accessory)
            return
        }

        if let settingsWindow = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeKey }) {
            settingsWindowObserver.map { NotificationCenter.default.removeObserver($0) }
            settingsWindowObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.willCloseNotification,
                object: settingsWindow,
                queue: .main
            ) { [weak self] _ in
                NSApp.setActivationPolicy(.accessory)
                if let observer = self?.settingsWindowObserver {
                    NotificationCenter.default.removeObserver(observer)
                    self?.settingsWindowObserver = nil
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.waitForSettingsWindow(attempts: attempts - 1)
            }
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func updateToggleMenuTitle() {
        toggleMenuItem?.title = settings.isActive ? "Highlight: On" : "Highlight: Off"
    }

    // MARK: - Setup

    private func setupOverlay() {
        overlayManager.createWindows()
    }

    private func setupMouseTracking() {
        mouseTracker.onMouseMoved = { [weak self] point in
            guard let self = self else { return }
            self.overlayManager.updateCursorPosition(point)
            self.idleTimer.resetTimer()

        }
        mouseTracker.start()
    }

    // MARK: - Cursor Type Color Detection

    private func setupCursorColorDetection() {
        // Cache cursor image data for reliable comparison (instead of == which uses object identity)
        if #available(macOS 13.0, *) {
            handCursorData = NSCursor.pointingHand.image.tiffRepresentation
            iBeamCursorData = NSCursor.iBeam.image.tiffRepresentation
            iBeamVerticalData = NSCursor.iBeamCursorForVerticalLayout.image.tiffRepresentation
        }

        cursorCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.pollCursorType()
        }
    }

    private func pollCursorType() {
        guard settings.isActive, settings.cursorColorEnabled else {
            if lastDetectedCursorType != .normal {
                lastDetectedCursorType = .normal
                overlayManager.setCursorTypeColor(nil)
            }
            return
        }

        var detected: DetectedCursorType = .normal

        // Method 1: Compare cursor image TIFF data (works for native apps with standard cursors)
        if #available(macOS 13.0, *), let systemCursor = NSCursor.currentSystem {
            if let currentData = systemCursor.image.tiffRepresentation {
                if currentData == handCursorData {
                    detected = .hand
                } else if currentData == iBeamCursorData || currentData == iBeamVerticalData {
                    detected = .iBeam
                }
            }
        }

        // Method 2: Accessibility API fallback (works for browsers and apps with custom cursors)
        if detected == .normal {
            detected = detectCursorTypeViaAccessibility()
        }

        if detected != lastDetectedCursorType {
            lastDetectedCursorType = detected
            switch detected {
            case .normal:
                overlayManager.setCursorTypeColor(nil)
            case .hand:
                overlayManager.setCursorTypeColor(settings.handCursorColor)
            case .iBeam:
                overlayManager.setCursorTypeColor(settings.iBeamCursorColor)
            }
        }
    }

    private func detectCursorTypeViaAccessibility() -> DetectedCursorType {
        let mouseLocation = NSEvent.mouseLocation
        guard let primaryScreen = NSScreen.screens.first else { return .normal }

        let axX = Float(mouseLocation.x)
        let axY = Float(primaryScreen.frame.height - mouseLocation.y)

        // Try frontmost application first (more reliable for app-specific elements)
        if let frontApp = NSWorkspace.shared.frontmostApplication {
            let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
            var axElement: AXUIElement?
            let result = AXUIElementCopyElementAtPosition(appElement, axX, axY, &axElement)

            if result == .success, let element = axElement {
                let type = classifyAXElement(element)
                if type != .normal { return type }
            }
        }

        // Fallback to system-wide
        let systemWide = AXUIElementCreateSystemWide()
        var axElement: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(systemWide, axX, axY, &axElement)
        guard result == .success, let element = axElement else { return .normal }
        return classifyAXElement(element)
    }

    private func classifyAXElement(_ element: AXUIElement) -> DetectedCursorType {
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, "AXRole" as CFString, &roleRef)
        let role = roleRef as? String ?? ""

        // Link detection
        if role == "AXLink" { return .hand }

        // Text input detection
        if role == "AXTextField" || role == "AXTextArea" || role == "AXComboBox" || role == "AXSearchField" {
            return .iBeam
        }

        // Check URL attribute (links typically have this)
        var urlRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, "AXURL" as CFString, &urlRef)
        if urlRef != nil { return .hand }

        // Check parent element (e.g. text node inside a link)
        var parentRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, "AXParent" as CFString, &parentRef)
        if let parent = parentRef {
            let parentElement = parent as! AXUIElement
            var parentRoleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(parentElement, "AXRole" as CFString, &parentRoleRef)
            let parentRole = parentRoleRef as? String ?? ""

            if parentRole == "AXLink" { return .hand }
            if parentRole == "AXTextField" || parentRole == "AXTextArea" { return .iBeam }
        }

        return .normal
    }

    private func setupClickDetection() {
        clickDetector.onClickDetected = { [weak self] clickType in
            self?.overlayManager.triggerClickAnimation(clickType: clickType)
        }
        clickDetector.start()
    }

    private func setupIdleTimer() {
        idleTimer.onIdle = { [weak self] in
            self?.overlayManager.setHighlightVisible(false, animated: true)
        }
        idleTimer.onResume = { [weak self] in
            self?.overlayManager.setHighlightVisible(true, animated: true)
        }
    }

    private func setupScreenObserver() {
        screenObserver.onScreensChanged = { [weak self] in
            self?.overlayManager.recreateWindows()
        }
        screenObserver.start()
    }

    private func setupHotkey() {
        hotkeyManager.onToggle = { [weak self] in
            guard let self = self else { return }
            self.settings.isActive.toggle()
        }
        hotkeyManager.register()
    }

    private func observeActiveState() {
        settings.$isActive.sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateToggleMenuTitle()
            }
        }.store(in: &cancellables)
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Refresh colors each time the menu opens
        rebuildMenu()
    }
}

// MARK: - Color Menu Item View

final class ColorMenuItemView: NSView {
    private let colorWell: NSColorWell
    private let label: NSTextField
    private var onChange: ((NSColor) -> Void)?
    private var observation: NSKeyValueObservation?

    init(title: String, color: NSColor, onChange: @escaping (NSColor) -> Void) {
        self.onChange = onChange
        self.colorWell = NSColorWell(frame: .zero)
        self.label = NSTextField(labelWithString: title)

        super.init(frame: NSRect(x: 0, y: 0, width: 200, height: 30))

        label.font = .menuFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        colorWell.color = color
        if #available(macOS 13.0, *) {
            colorWell.colorWellStyle = .minimal
        }
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.target = self
        colorWell.action = #selector(colorChanged)
        addSubview(colorWell)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            colorWell.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            colorWell.centerYAnchor.constraint(equalTo: centerYAnchor),
            colorWell.widthAnchor.constraint(equalToConstant: 36),
            colorWell.heightAnchor.constraint(equalToConstant: 22),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func colorChanged() {
        onChange?(colorWell.color)
    }
}
