import AppKit
import Combine
import ServiceManagement

final class CursorSettings: ObservableObject {
    static let shared = CursorSettings()

    @Published var isActive: Bool {
        didSet { UserDefaults.standard.set(isActive, forKey: "isActive") }
    }

    // Appearance
    @Published var shape: HighlightShape {
        didSet { UserDefaults.standard.set(shape.rawValue, forKey: "shape") }
    }
    @Published var highlightSize: CGFloat {
        didSet { UserDefaults.standard.set(Double(highlightSize), forKey: "highlightSize") }
    }
    @Published var borderWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(borderWidth), forKey: "borderWidth") }
    }
    @Published var highlightColor: NSColor {
        didSet { UserDefaults.standard.set(highlightColor.hexString, forKey: "highlightColor") }
    }
    @Published var glowIntensity: CGFloat {
        didSet { UserDefaults.standard.set(Double(glowIntensity), forKey: "glowIntensity") }
    }

    // Cursor offset (to center on cursor body instead of tip)
    @Published var cursorOffsetX: CGFloat {
        didSet { UserDefaults.standard.set(Double(cursorOffsetX), forKey: "cursorOffsetX") }
    }
    @Published var cursorOffsetY: CGFloat {
        didSet { UserDefaults.standard.set(Double(cursorOffsetY), forKey: "cursorOffsetY") }
    }

    // Cursor-type colors
    @Published var cursorColorEnabled: Bool {
        didSet { UserDefaults.standard.set(cursorColorEnabled, forKey: "cursorColorEnabled") }
    }
    @Published var handCursorColor: NSColor {
        didSet { UserDefaults.standard.set(handCursorColor.hexString, forKey: "handCursorColor") }
    }
    @Published var iBeamCursorColor: NSColor {
        didSet { UserDefaults.standard.set(iBeamCursorColor.hexString, forKey: "iBeamCursorColor") }
    }

    // Click animation
    @Published var clickAnimationEnabled: Bool {
        didSet { UserDefaults.standard.set(clickAnimationEnabled, forKey: "clickAnimationEnabled") }
    }
    @Published var clickBorderWidth: CGFloat {
        didSet { UserDefaults.standard.set(Double(clickBorderWidth), forKey: "clickBorderWidth") }
    }
    @Published var leftClickColor: NSColor {
        didSet { UserDefaults.standard.set(leftClickColor.hexString, forKey: "leftClickColor") }
    }
    @Published var rightClickColor: NSColor {
        didSet { UserDefaults.standard.set(rightClickColor.hexString, forKey: "rightClickColor") }
    }

    // Auto-hide
    @Published var autoHideEnabled: Bool {
        didSet { UserDefaults.standard.set(autoHideEnabled, forKey: "autoHideEnabled") }
    }
    @Published var autoHideDelay: TimeInterval {
        didSet { UserDefaults.standard.set(autoHideDelay, forKey: "autoHideDelay") }
    }

    // Launch at Login
    @Published var launchAtLogin: Bool {
        didSet {
            if #available(macOS 13.0, *) {
                do {
                    if launchAtLogin {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    // Revert on failure
                    DispatchQueue.main.async { self.launchAtLogin = !self.launchAtLogin }
                }
            }
        }
    }

    enum Defaults {
        static let shape: HighlightShape = .squircle
        static let highlightSize: Double = 105
        static let borderWidth: Double = 4.5
        static let highlightColor = NSColor(hex: "#00FFFF")!
        static let glowIntensity: Double = 0.7
        static let cursorOffsetX: Double = 0
        static let cursorOffsetY: Double = -4
        static let cursorColorEnabled = true
        static let handCursorColor = NSColor(hex: "#39FF14")!
        static let iBeamCursorColor = NSColor(hex: "#BF00FF")!
        static let clickAnimationEnabled = true
        static let clickBorderWidth: Double = 3.5
        static let leftClickColor = NSColor(hex: "#FFFF00")!
        static let rightClickColor = NSColor(hex: "#FF073A")!
        static let autoHideEnabled = true
        static let autoHideDelay: Double = 5.0
    }

    func restoreDefaults() {
        shape = Defaults.shape
        highlightSize = Defaults.highlightSize
        borderWidth = Defaults.borderWidth
        highlightColor = Defaults.highlightColor
        glowIntensity = Defaults.glowIntensity
        cursorOffsetX = Defaults.cursorOffsetX
        cursorOffsetY = Defaults.cursorOffsetY
        cursorColorEnabled = Defaults.cursorColorEnabled
        handCursorColor = Defaults.handCursorColor
        iBeamCursorColor = Defaults.iBeamCursorColor
        clickAnimationEnabled = Defaults.clickAnimationEnabled
        clickBorderWidth = Defaults.clickBorderWidth
        leftClickColor = Defaults.leftClickColor
        rightClickColor = Defaults.rightClickColor
        autoHideEnabled = Defaults.autoHideEnabled
        autoHideDelay = Defaults.autoHideDelay
    }

    private init() {
        let defaults = UserDefaults.standard

        self.isActive = defaults.object(forKey: "isActive") as? Bool ?? true
        self.shape = HighlightShape(rawValue: defaults.string(forKey: "shape") ?? "") ?? Defaults.shape
        self.highlightSize = CGFloat(defaults.object(forKey: "highlightSize") as? Double ?? Defaults.highlightSize)
        self.borderWidth = CGFloat(defaults.object(forKey: "borderWidth") as? Double ?? Defaults.borderWidth)
        self.highlightColor = NSColor(hex: defaults.string(forKey: "highlightColor") ?? "") ?? Defaults.highlightColor
        self.glowIntensity = CGFloat(defaults.object(forKey: "glowIntensity") as? Double ?? Defaults.glowIntensity)
        self.cursorOffsetX = CGFloat(defaults.object(forKey: "cursorOffsetX") as? Double ?? Defaults.cursorOffsetX)
        self.cursorOffsetY = CGFloat(defaults.object(forKey: "cursorOffsetY") as? Double ?? Defaults.cursorOffsetY)
        self.cursorColorEnabled = defaults.object(forKey: "cursorColorEnabled") as? Bool ?? Defaults.cursorColorEnabled
        self.handCursorColor = NSColor(hex: defaults.string(forKey: "handCursorColor") ?? "") ?? Defaults.handCursorColor
        self.iBeamCursorColor = NSColor(hex: defaults.string(forKey: "iBeamCursorColor") ?? "") ?? Defaults.iBeamCursorColor
        self.clickAnimationEnabled = defaults.object(forKey: "clickAnimationEnabled") as? Bool ?? Defaults.clickAnimationEnabled
        self.clickBorderWidth = CGFloat(defaults.object(forKey: "clickBorderWidth") as? Double ?? Defaults.clickBorderWidth)
        self.leftClickColor = NSColor(hex: defaults.string(forKey: "leftClickColor") ?? "") ?? Defaults.leftClickColor
        self.rightClickColor = NSColor(hex: defaults.string(forKey: "rightClickColor") ?? "") ?? Defaults.rightClickColor
        self.autoHideEnabled = defaults.object(forKey: "autoHideEnabled") as? Bool ?? Defaults.autoHideEnabled
        self.autoHideDelay = defaults.object(forKey: "autoHideDelay") as? TimeInterval ?? Defaults.autoHideDelay
        if #available(macOS 13.0, *) {
            self.launchAtLogin = SMAppService.mainApp.status == .enabled
        } else {
            self.launchAtLogin = false
        }
    }
}
