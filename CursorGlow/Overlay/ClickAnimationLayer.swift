import AppKit
import QuartzCore

final class ClickAnimationLayer: CALayer {
    private let ringLayer = CAShapeLayer()
    private var currentShape: HighlightShape = .circle
    private var currentSize: CGFloat = 50
    private var currentBorderWidth: CGFloat = 2

    override init() {
        super.init()
        setup()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        updateLayerSize()

        ringLayer.fillColor = nil
        ringLayer.lineWidth = currentBorderWidth
        ringLayer.opacity = 0

        addSublayer(ringLayer)
    }

    func updateShape(_ shape: HighlightShape, size: CGFloat, borderWidth: CGFloat) {
        currentShape = shape
        currentSize = size
        currentBorderWidth = borderWidth
        updateLayerSize()
    }

    private func updateLayerSize() {
        let layerSize = currentSize + 20
        bounds = CGRect(x: 0, y: 0, width: layerSize, height: layerSize)
        ringLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        ringLayer.bounds = bounds
        ringLayer.position = CGPoint(x: layerSize / 2, y: layerSize / 2)

        let shapeRect = bounds.insetBy(dx: 10, dy: 10)
        ringLayer.path = ShapePathHelper.path(for: currentShape, in: shapeRect)
        ringLayer.lineWidth = currentBorderWidth
    }

    func animate(color: NSColor) {
        ringLayer.strokeColor = color.cgColor
        ringLayer.removeAllAnimations()

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.7
        scaleAnim.toValue = 2.0

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0.8
        opacityAnim.toValue = 0.0

        let group = CAAnimationGroup()
        group.animations = [scaleAnim, opacityAnim]
        group.duration = 0.35
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = true

        ringLayer.opacity = 0
        ringLayer.add(group, forKey: "clickRipple")
    }
}
