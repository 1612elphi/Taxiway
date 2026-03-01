import SwiftUI

struct SymbolFieldView: View {
    let cursorPosition: CGPoint?

    private static let symbols = [
        "textformat", "character", "bold.italic.underline",
        "paragraph", "text.alignleft", "doc.text",
        "paintpalette", "ruler", "photo",
        "magnifyingglass", "printer", "scissors",
        "a.magnify", "textformat.size", "pencil.and.ruler",
        "textformat.subscript", "crop", "doc.richtext",
        "eye", "text.aligncenter", "paintbrush", "pencil",
    ]

    // Concentric rings: (radius from center, number of icons)
    private static let rings: [(radius: CGFloat, count: Int)] = [
        (78, 6),
        (124, 10),
        (174, 14),
        (228, 18),
        (286, 22),
    ]

    // Precomputed polar placements
    private struct Placement: Identifiable {
        let id: Int
        let symbol: String
        let ring: Int
        let angle: Double
        let radius: CGFloat
    }

    private static let placements: [Placement] = {
        var result: [Placement] = []
        var idx = 0
        for (ringIndex, ring) in rings.enumerated() {
            // Offset every other ring by half-step for honeycomb packing
            let offset = ringIndex.isMultiple(of: 2) ? 0.0 : .pi / Double(ring.count)
            for i in 0..<ring.count {
                let angle = 2 * .pi * Double(i) / Double(ring.count) + offset
                result.append(Placement(
                    id: idx,
                    symbol: symbols[(idx &* 7 &+ 3) % symbols.count],
                    ring: ringIndex,
                    angle: angle,
                    radius: ring.radius
                ))
                idx += 1
            }
        }
        return result
    }()

    // Size and opacity per ring (bigger & brighter near center)
    private static let ringBaseSize: [CGFloat] = [20, 17, 14, 12, 10]
    private static let ringBaseOpacity: [Double] = [0, 0.08, 0.06, 0.045, 0.035]

    private let influenceRadius: CGFloat = 130
    private let maxSizeBoost: CGFloat = 10
    private let maxOpacityBoost: Double = 0.14
    private let maxPush: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.38)

            ForEach(Self.placements) { p in
                let baseX = center.x + p.radius * CGFloat(cos(p.angle))
                let baseY = center.y + p.radius * CGFloat(sin(p.angle))
                let pos = CGPoint(x: baseX, y: baseY)

                let dist = cursorDistance(from: pos)
                let influence = max(0, 1 - dist / influenceRadius)
                let fisheye = influence * influence // quadratic for snappy falloff

                let size = Self.ringBaseSize[p.ring] + maxSizeBoost * fisheye
                let opacity = Self.ringBaseOpacity[p.ring] + maxOpacityBoost * fisheye
                let push = displacement(from: pos)

                Image(systemName: p.symbol)
                    .font(.system(size: size, weight: .light))
                    .foregroundStyle(Color.primary.opacity(opacity))
                    .offset(x: push.width, y: push.height)
                    .position(x: baseX, y: baseY)
                    .animation(
                        .interactiveSpring(response: 0.3, dampingFraction: 0.7),
                        value: cursorPosition?.x
                    )
                    .animation(
                        .interactiveSpring(response: 0.3, dampingFraction: 0.7),
                        value: cursorPosition?.y
                    )
            }
        }
        .allowsHitTesting(false)
    }

    private func cursorDistance(from point: CGPoint) -> CGFloat {
        guard let cursor = cursorPosition else { return .infinity }
        let dx = point.x - cursor.x
        let dy = point.y - cursor.y
        return sqrt(dx * dx + dy * dy)
    }

    private func displacement(from point: CGPoint) -> CGSize {
        guard let cursor = cursorPosition else { return .zero }
        let dx = point.x - cursor.x
        let dy = point.y - cursor.y
        let dist = sqrt(dx * dx + dy * dy)
        guard dist > 1, dist < influenceRadius else { return .zero }
        let strength = pow(1 - dist / influenceRadius, 2)
        return CGSize(
            width: dx / dist * maxPush * strength,
            height: dy / dist * maxPush * strength
        )
    }
}
