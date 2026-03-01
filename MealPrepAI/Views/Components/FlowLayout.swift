import SwiftUI

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    struct CacheData {
        var result: FlowResult
    }

    func makeCache(subviews: Subviews) -> CacheData {
        CacheData(result: FlowResult(in: 0, subviews: subviews, spacing: spacing))
    }

    func updateCache(_ cache: inout CacheData, subviews: Subviews) {
        // Cache is invalidated automatically when subviews change;
        // recompute with width 0 as a placeholder — sizeThatFits will recalculate with the real width.
        cache.result = FlowResult(in: 0, subviews: subviews, spacing: spacing)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) -> CGSize {
        let width = proposal.width ?? 0
        if cache.result.width != width {
            cache.result = FlowResult(in: width, subviews: subviews, spacing: spacing)
        }
        return cache.result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout CacheData) {
        if cache.result.width != bounds.width {
            cache.result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        }
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + cache.result.positions[index].x, y: bounds.minY + cache.result.positions[index].y),
                proposal: .unspecified
            )
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        var width: CGFloat = 0

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            self.width = maxWidth
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}
