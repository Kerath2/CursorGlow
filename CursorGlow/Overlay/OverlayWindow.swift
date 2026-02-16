import AppKit

final class OverlayWindow: NSWindow {
    convenience init(screen: NSScreen) {
        self.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        self.isReleasedWhenClosed = false

        let overlayView = OverlayView(frame: screen.frame)
        self.contentView = overlayView

        self.setFrame(screen.frame, display: true)
    }

    var overlayView: OverlayView? {
        contentView as? OverlayView
    }
}
