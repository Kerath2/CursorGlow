import SwiftUI

struct PreviewCursorView: View {
    @ObservedObject var settings: CursorSettings

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                // Scale preview to fit in the box
                let s = min(settings.highlightSize, 100)
                let rect = CGRect(x: center.x - s / 2, y: center.y - s / 2, width: s, height: s)
                let color = Color(nsColor: settings.highlightColor)
                let path = shapePath(in: rect)

                // Outer glow
                context.addFilter(.shadow(color: color.opacity(settings.glowIntensity * 0.6), radius: 16 * settings.glowIntensity))
                context.stroke(path, with: .color(color), lineWidth: settings.borderWidth)

                // Border only - no fill
                context.stroke(path, with: .color(color), lineWidth: settings.borderWidth)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func shapePath(in rect: CGRect) -> Path {
        switch settings.shape {
        case .circle:
            return Path(ellipseIn: rect)
        case .roundedSquare:
            return Path(roundedRect: rect, cornerRadius: rect.width * 0.2)
        case .rhombus:
            return roundedRhombusPath(in: rect, cornerRadius: rect.width * 0.15)
        case .squircle:
            return superellipsePath(in: rect, n: 1.6)
        }
    }

    private func superellipsePath(in rect: CGRect, n: CGFloat) -> Path {
        let cx = rect.midX, cy = rect.midY
        let a = rect.width / 2, b = rect.height / 2
        let segments = 100

        func sign(_ v: CGFloat) -> CGFloat { v >= 0 ? 1 : -1 }

        var path = Path()
        for i in 0...segments {
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

    private func roundedRhombusPath(in rect: CGRect, cornerRadius: CGFloat) -> Path {
        let cx = rect.midX, cy = rect.midY
        let hw = rect.width / 2, hh = rect.height / 2
        let r = min(cornerRadius, min(hw, hh) * 0.5)

        let top = CGPoint(x: cx, y: cy - hh)
        let right = CGPoint(x: cx + hw, y: cy)
        let bottom = CGPoint(x: cx, y: cy + hh)
        let left = CGPoint(x: cx - hw, y: cy)

        func toward(_ from: CGPoint, _ to: CGPoint, dist: CGFloat) -> CGPoint {
            let dx = to.x - from.x, dy = to.y - from.y
            let len = sqrt(dx * dx + dy * dy)
            let t = dist / len
            return CGPoint(x: from.x + dx * t, y: from.y + dy * t)
        }

        var path = Path()
        let startPt = toward(top, right, dist: r)
        path.move(to: startPt)

        path.addLine(to: toward(right, top, dist: r))
        path.addQuadCurve(to: toward(right, bottom, dist: r), control: right)

        path.addLine(to: toward(bottom, right, dist: r))
        path.addQuadCurve(to: toward(bottom, left, dist: r), control: bottom)

        path.addLine(to: toward(left, bottom, dist: r))
        path.addQuadCurve(to: toward(left, top, dist: r), control: left)

        path.addLine(to: toward(top, left, dist: r))
        path.addQuadCurve(to: startPt, control: top)

        path.closeSubpath()
        return path
    }
}
