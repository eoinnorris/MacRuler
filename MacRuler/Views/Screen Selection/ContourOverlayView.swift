//
//  ContourOverlayView.swift
//  MacRuler
//

import SwiftUI



struct ContourOverlayView: View {
    let normalizedContours: [CGPath]
    let contentOrigin: CGPoint
    let imageSize: CGSize
    let pathOffset: CGPoint
    /// The magnification factor applied to the view, used to convert displayed
    /// points back to real (unmagnified) units for the distance label.
    let magnification: CGFloat
    
    let maxGap = 10.0

    @State private var mouseLocation: CGPoint? = nil

    // MARK: - Helpers

    /// Builds the affine transform that maps Vision's normalised coordinate
    /// space (origin bottom-left, 0–1) into the view's flipped point space.
    private var contourTransform: CGAffineTransform {
        var t = CGAffineTransform(translationX: contentOrigin.x, y: contentOrigin.y)
        t = t.concatenating(
            CGAffineTransform(
                a: imageSize.width,
                b: 0,
                c: 0,
                d: -imageSize.height,
                tx: 0,
                ty: imageSize.height
            )
        )
        return t
    }

    /// Returns the valid (non-degenerate) bounding rects for all contours,
    /// already mapped into view space.
    private func mappedBounds() -> [CGRect] {
        let t = contourTransform
        return normalizedContours.compactMap { path -> CGRect? in
            var transform = t
            guard let mapped = path.copy(using: &transform) else { return nil }
            let b = mapped.boundingBoxOfPath
            guard !b.isNull, !b.isInfinite, b.width > 2, b.height > 2 else { return nil }
            return b
        }
    }

    // MARK: - Measurement

    struct Measurement {
        enum Axis { case horizontal, vertical }
        let axis: Axis
        let start: CGFloat    // leading edge of gap (maxX of left rect, or maxY of top rect)
        let end: CGFloat      // trailing edge of gap (minX of right rect, or minY of bottom rect)
        let crossAxis: CGFloat // Y for horizontal line, X for vertical line
        /// Distance in real (unmagnified) points.
        let realDistance: CGFloat
    }

    /// For the given mouse position, returns the closest qualifying gap
    /// the pointer sits inside. Checks horizontal first, then vertical.
    private func measurement(at point: CGPoint, in rects: [CGRect]) -> Measurement? {

        // HORIZONTAL: find the nearest rect-edge to the left and right of the
        // cursor, where both rects also vertically overlap the cursor's Y.
        let hLeft = rects
            .filter { $0.maxX < point.x && $0.minY <= point.y && $0.maxY >= point.y }
            .max(by: { $0.maxX < $1.maxX })

        let hRight = rects
            .filter { $0.minX > point.x && $0.minY <= point.y && $0.maxY >= point.y }
            .min(by: { $0.minX < $1.minX })

        if let l = hLeft, let r = hRight {
            let gap = r.minX - l.maxX
            let realGap = gap / magnification
            if realGap >= maxGap {
                return Measurement(
                    axis: .horizontal,
                    start: l.maxX,
                    end: r.minX,
                    crossAxis: point.y,
                    realDistance: realGap
                )
            }
        }

        // VERTICAL: find the nearest rect-edge above and below the cursor,
        // where both rects also horizontally overlap the cursor's X.
        let vAbove = rects
            .filter { $0.maxY < point.y && $0.minX <= point.x && $0.maxX >= point.x }
            .max(by: { $0.maxY < $1.maxY })

        let vBelow = rects
            .filter { $0.minY > point.y && $0.minX <= point.x && $0.maxX >= point.x }
            .min(by: { $0.minY < $1.minY })

        if let a = vAbove, let b = vBelow {
            let gap = b.minY - a.maxY
            let realGap = gap / magnification
            if realGap >= maxGap {
                return Measurement(
                    axis: .vertical,
                    start: a.maxY,
                    end: b.minY,
                    crossAxis: point.x,
                    realDistance: realGap
                )
            }
        }

        return nil
    }

    // MARK: - Drawing

    private func drawMeasurement(_ m: Measurement, in context: GraphicsContext) {
        let arrowSize: CGFloat = 6
        let color = Color.yellow
        let style = StrokeStyle(lineWidth: 1.5)
        let label = "\(Int(m.realDistance.rounded())) pt"
        let labelText = Text(label)
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .foregroundColor(.white)

        switch m.axis {

        // ── Horizontal ──────────────────────────────────────────────────────
        case .horizontal:
            let y  = m.crossAxis
            let x0 = m.start
            let x1 = m.end

            // Measurement line
            var line = Path()
            line.move(to: CGPoint(x: x0, y: y))
            line.addLine(to: CGPoint(x: x1, y: y))
            context.stroke(line, with: .color(color), style: style)

            // Tick at left end
            var leftTick = Path()
            leftTick.move(to: CGPoint(x: x0, y: y - 4))
            leftTick.addLine(to: CGPoint(x: x0, y: y + 4))
            context.stroke(leftTick, with: .color(color), style: style)

            // Right-pointing filled arrowhead at x1
            var arrow = Path()
            arrow.move(to: CGPoint(x: x1, y: y))
            arrow.addLine(to: CGPoint(x: x1 - arrowSize, y: y - arrowSize / 2))
            arrow.addLine(to: CGPoint(x: x1 - arrowSize, y: y + arrowSize / 2))
            arrow.closeSubpath()
            context.fill(arrow, with: .color(color))

            // Label centred above the midpoint of the gap
            let mid = CGPoint(x: (x0 + x1) / 2, y: y - 14)
            context.draw(labelText, at: mid, anchor: .center)

        // ── Vertical ────────────────────────────────────────────────────────
        case .vertical:
            let x  = m.crossAxis
            let y0 = m.start
            let y1 = m.end

            // Measurement line
            var line = Path()
            line.move(to: CGPoint(x: x, y: y0))
            line.addLine(to: CGPoint(x: x, y: y1))
            context.stroke(line, with: .color(color), style: style)

            // Tick at top end
            var topTick = Path()
            topTick.move(to: CGPoint(x: x - 4, y: y0))
            topTick.addLine(to: CGPoint(x: x + 4, y: y0))
            context.stroke(topTick, with: .color(color), style: style)

            // Bottom-pointing filled arrowhead at y1
            var arrow = Path()
            arrow.move(to: CGPoint(x: x, y: y1))
            arrow.addLine(to: CGPoint(x: x - arrowSize / 2, y: y1 - arrowSize))
            arrow.addLine(to: CGPoint(x: x + arrowSize / 2, y: y1 - arrowSize))
            arrow.closeSubpath()
            context.fill(arrow, with: .color(color))

            // Label to the left of the midpoint of the gap
            let mid = CGPoint(x: x - 10, y: (y0 + y1) / 2)
            context.draw(labelText, at: mid, anchor: .trailing)
        }
    }

    // MARK: - Body

    var body: some View {
        let rects = mappedBounds()

        Canvas { context, _ in
            guard !normalizedContours.isEmpty else { return }

            let t = contourTransform

            // Draw contours and their bounding rects
            for normalizedPath in normalizedContours {
                var pathTransform = t
                guard let mappedPath = normalizedPath.copy(using: &pathTransform) else { continue }

                context.stroke(
                    Path(mappedPath),
                    with: .color(.blue.opacity(0.95)),
                    style: StrokeStyle(lineWidth: 1, lineCap: .butt, lineJoin: .miter)
                )

                let bounds = mappedPath.boundingBoxOfPath
                if !bounds.isNull && !bounds.isInfinite && bounds.width > 2 && bounds.height > 2 {
                    context.stroke(
                        Path(bounds),
                        with: .color(.orange.opacity(0.75)),
                        style: StrokeStyle(lineWidth: 1, lineCap: .square, lineJoin: .miter, dash: [4, 3])
                    )
                }
            }

            // Draw measurement line if mouse is between two qualifying rects
            if let point = mouseLocation,
               let m = measurement(at: point, in: rects) {
                drawMeasurement(m, in: context)
            }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                mouseLocation = location
            case .ended:
                mouseLocation = nil
            }
        }
        .accessibilityHidden(true)
    }
}
