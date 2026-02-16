import AppKit
import QuartzCore

final class OverlayView: NSView {
    let highlightLayer = CursorHighlightLayer()
    let clickAnimationLayer = ClickAnimationLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.addSublayer(highlightLayer)
        layer?.addSublayer(clickAnimationLayer)

        let settings = CursorSettings.shared
        clickAnimationLayer.updateShape(settings.shape, size: settings.highlightSize, borderWidth: settings.clickBorderWidth)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayer() {
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    func updateHighlightPosition(_ point: NSPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        highlightLayer.position = point
        clickAnimationLayer.position = point
        CATransaction.commit()
    }

    func updateHighlightAppearance(settings: CursorSettings) {
        highlightLayer.updateAppearance(settings: settings)
        clickAnimationLayer.updateShape(settings.shape, size: settings.highlightSize, borderWidth: settings.clickBorderWidth)
    }

    func updateHighlightColor(_ color: NSColor) {
        highlightLayer.updateColor(color.cgColor)
    }

    func triggerClickAnimation(color: NSColor) {
        highlightLayer.animatePress()
        clickAnimationLayer.animate(color: color)
    }
}
