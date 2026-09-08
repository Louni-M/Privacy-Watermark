import Foundation
import CoreGraphics

/// Screen-space geometry only; never allocates a raster for the page strip.
public struct PreviewLayout: Equatable, Sendable {
    public let sizes: [CGSize]
    public let scale: CGFloat
    public let pages: [CGRect]
    public let extent: CGSize
    public static let gap: CGFloat = 16

    public init(sizes: [CGSize], scale: CGFloat, viewport: CGSize) {
        self.sizes = sizes
        self.scale = scale
        let width = max(viewport.width, (sizes.map(\.width).max() ?? 0) * scale)
        let height = sizes.reduce(0) { $0 + $1.height * scale } + CGFloat(max(0, sizes.count - 1)) * Self.gap
        var y = max(0, (viewport.height - height) / 2)
        pages = sizes.map { size in
            let rect = CGRect(x: (width - size.width * scale) / 2, y: y,
                width: size.width * scale, height: size.height * scale)
            y += rect.height + Self.gap
            return rect
        }
        extent = CGSize(width: width, height: max(viewport.height, height))
    }

    public func currentPage(at point: CGPoint) -> Int? {
        pages.indices.min { distance(point, pages[$0]) < distance(point, pages[$1]) }
    }

    private func distance(_ point: CGPoint, _ rect: CGRect) -> CGFloat {
        // Page selection follows vertical position, including horizontal margins.
        max(rect.minY - point.y, 0, point.y - rect.maxY)
    }

    public func regions(in viewport: CGRect) -> [Int: CGRect] {
        var result: [Int: CGRect] = [:]
        for (index, page) in pages.enumerated() {
            let rect = page.intersection(viewport)
            guard !rect.isNull, !rect.isEmpty else { continue }
            result[index] = CGRect(x: (rect.minX - page.minX) / scale,
                y: sizes[index].height - (rect.maxY - page.minY) / scale,
                width: rect.width / scale, height: rect.height / scale)
        }
        return result
    }

    public struct Anchor: Equatable, Sendable {
        public let page: Int
        /// Top-left page-local document coordinates.
        public let point: CGPoint
    }

    public func anchor(at point: CGPoint) -> Anchor? {
        guard let index = currentPage(at: point) else { return nil }
        let rect = pages[index]
        return Anchor(page: index, point: CGPoint(x: min(rect.width, max(0, point.x - rect.minX)) / scale,
            y: min(rect.height, max(0, point.y - rect.minY)) / scale))
    }

    public func position(of anchor: Anchor) -> CGPoint {
        guard pages.indices.contains(anchor.page) else { return .zero }
        return CGPoint(x: pages[anchor.page].minX + anchor.point.x * scale,
            y: pages[anchor.page].minY + anchor.point.y * scale)
    }

    public func clamped(_ origin: CGPoint, viewport: CGSize) -> CGPoint {
        CGPoint(x: min(max(0, extent.width - viewport.width), max(0, origin.x)),
            y: min(max(0, extent.height - viewport.height), max(0, origin.y)))
    }
}
