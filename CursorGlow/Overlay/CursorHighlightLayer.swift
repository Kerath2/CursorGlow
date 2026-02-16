import AppKit
import QuartzCore

final class CursorHighlightLayer: CALayer {
    private let shapeLayer = CAShapeLayer()
    private let innerBorderLayer = CAShapeLayer()
    private let innerGlowLayer = CALayer()
    private let outerGlowLayer = CALayer()

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
        addSublayer(outerGlowLayer)
        addSublayer(innerGlowLayer)
        addSublayer(innerBorderLayer)
        addSublayer(shapeLayer)

        shapeLayer.fillColor = nil
        shapeLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        innerBorderLayer.fillColor = nil
        innerBorderLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        innerGlowLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        outerGlowLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        updateAppearance(settings: CursorSettings.shared)
    }

    func updateAppearance(settings: CursorSettings) {
        let size = settings.highlightSize
        let color = settings.highlightColor.cgColor
        let glowIntensity = settings.glowIntensity
        let lineWidth = settings.borderWidth

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        let layerSize = CGSize(width: size + 60, height: size + 60)
        bounds = CGRect(origin: .zero, size: layerSize)

        let shapeRect = CGRect(
            x: (layerSize.width - size) / 2,
            y: (layerSize.height - size) / 2,
            width: size,
            height: size
        )
        let path = ShapePathHelper.path(for: settings.shape, in: shapeRect)

        // Create a stroked version of the path for glow shadows
        // This ensures glow only follows the border, not the filled interior
        let strokePath = path.copy(strokingWithWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 10)

        // Shape border only - no fill
        shapeLayer.bounds = CGRect(origin: .zero, size: layerSize)
        shapeLayer.position = CGPoint(x: layerSize.width / 2, y: layerSize.height / 2)
        shapeLayer.path = path
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = lineWidth
        shapeLayer.fillColor = nil

        // Inner border - inset, same color but translucent + blurred for depth
        let inset = lineWidth + 1.5
        let innerRect = shapeRect.insetBy(dx: inset, dy: inset)
        let innerPath = ShapePathHelper.path(for: settings.shape, in: innerRect)
        innerBorderLayer.bounds = CGRect(origin: .zero, size: layerSize)
        innerBorderLayer.position = CGPoint(x: layerSize.width / 2, y: layerSize.height / 2)
        innerBorderLayer.path = innerPath
        innerBorderLayer.strokeColor = color.copy(alpha: 0.35)
        innerBorderLayer.lineWidth = lineWidth * 1.2
        innerBorderLayer.fillColor = nil
        if let blur = CIFilter(name: "CIGaussianBlur", parameters: [kCIInputRadiusKey: 2.5]) {
            innerBorderLayer.filters = [blur]
        }

        // Inner glow (tight, bright) - uses stroked path
        innerGlowLayer.bounds = CGRect(origin: .zero, size: layerSize)
        innerGlowLayer.position = CGPoint(x: layerSize.width / 2, y: layerSize.height / 2)
        innerGlowLayer.backgroundColor = NSColor.clear.cgColor
        innerGlowLayer.shadowColor = color
        innerGlowLayer.shadowOpacity = Float(min(glowIntensity * 1.2, 1.0))
        innerGlowLayer.shadowRadius = 8 * glowIntensity
        innerGlowLayer.shadowOffset = .zero
        innerGlowLayer.shadowPath = strokePath

        // Outer glow (wide, diffuse) - uses stroked path
        outerGlowLayer.bounds = CGRect(origin: .zero, size: layerSize)
        outerGlowLayer.position = CGPoint(x: layerSize.width / 2, y: layerSize.height / 2)
        outerGlowLayer.backgroundColor = NSColor.clear.cgColor
        outerGlowLayer.shadowColor = color
        outerGlowLayer.shadowOpacity = Float(glowIntensity * 0.6)
        outerGlowLayer.shadowRadius = 20 * glowIntensity
        outerGlowLayer.shadowOffset = .zero
        outerGlowLayer.shadowPath = strokePath

        CATransaction.commit()
    }

    func animatePress() {
        removeAllAnimations()

        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = 1.0
        scaleDown.toValue = 0.8
        scaleDown.duration = 0.08
        scaleDown.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.fromValue = 0.8
        scaleUp.toValue = 1.0
        scaleUp.beginTime = 0.08
        scaleUp.duration = 0.15
        scaleUp.timingFunction = CAMediaTimingFunction(name: .easeOut)

        let group = CAAnimationGroup()
        group.animations = [scaleDown, scaleUp]
        group.duration = 0.23
        group.fillMode = .forwards
        group.isRemovedOnCompletion = true

        add(group, forKey: "press")
    }

    func updateColor(_ color: CGColor) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.strokeColor = color
        innerBorderLayer.strokeColor = color.copy(alpha: 0.35)
        innerGlowLayer.shadowColor = color
        outerGlowLayer.shadowColor = color
        CATransaction.commit()
    }
}

// Shared helper so both highlight and click animation use the same shapes
enum ShapePathHelper {
    static func path(for shape: HighlightShape, in rect: CGRect) -> CGPath {
        switch shape {
        case .circle:
            return CGPath(ellipseIn: rect, transform: nil)
        case .rhombus:
            return roundedRhombusPath(in: rect, cornerRadius: rect.width * 0.15)
        case .roundedSquare:
            return CGPath(roundedRect: rect, cornerWidth: rect.width * 0.2, cornerHeight: rect.height * 0.2, transform: nil)
        case .squircle:
            return superellipsePath(in: rect, n: 1.6)
        }
    }

    /// Superellipse (squircle): |x/a|^n + |y/b|^n = 1, rotated 45 degrees
    private static func superellipsePath(in rect: CGRect, n: CGFloat) -> CGPath {
        let cx = rect.midX, cy = rect.midY
        let a = rect.width / 2, b = rect.height / 2
        let segments = 100
        let path = CGMutablePath()

        func sign(_ v: CGFloat) -> CGFloat { v >= 0 ? 1 : -1 }

        for i in 0...segments {
            // Angle rotated 45° so points sit at top/bottom/left/right
            let t = CGFloat(i) / CGFloat(segments) * 2 * .pi + .pi / 4
            let cosT = cos(t), sinT = sin(t)

            let x = cx + a * sign(cosT) * pow(abs(cosT), 2.0 / n)
            let y = cy + b * sign(sinT) * pow(abs(sinT), 2.0 / n)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    /// Rhombus (diamond) with rounded corners using quad curves at each vertex
    private static func roundedRhombusPath(in rect: CGRect, cornerRadius: CGFloat) -> CGPath {
        let cx = rect.midX, cy = rect.midY
        let hw = rect.width / 2, hh = rect.height / 2
        let r = min(cornerRadius, min(hw, hh) * 0.5)

        // The 4 vertices of the diamond
        let top = CGPoint(x: cx, y: cy + hh)
        let right = CGPoint(x: cx + hw, y: cy)
        let bottom = CGPoint(x: cx, y: cy - hh)
        let left = CGPoint(x: cx - hw, y: cy)

        let path = CGMutablePath()

        // Helper: point along the line from `from` toward `to`, at distance `dist` from `from`
        func toward(_ from: CGPoint, _ to: CGPoint, dist: CGFloat) -> CGPoint {
            let dx = to.x - from.x, dy = to.y - from.y
            let len = sqrt(dx * dx + dy * dy)
            let t = dist / len
            return CGPoint(x: from.x + dx * t, y: from.y + dy * t)
        }

        // Start near the top vertex, offset toward the right
        let startPt = toward(top, right, dist: r)
        path.move(to: startPt)

        // Top vertex -> curve
        path.addLine(to: toward(right, top, dist: r))
        path.addQuadCurve(to: toward(right, bottom, dist: r), control: right)

        // Right vertex -> curve
        path.addLine(to: toward(bottom, right, dist: r))
        path.addQuadCurve(to: toward(bottom, left, dist: r), control: bottom)

        // Bottom vertex -> curve
        path.addLine(to: toward(left, bottom, dist: r))
        path.addQuadCurve(to: toward(left, top, dist: r), control: left)

        // Left vertex -> curve
        path.addLine(to: toward(top, left, dist: r))
        path.addQuadCurve(to: startPt, control: top)

        path.closeSubpath()
        return path
    }
}
