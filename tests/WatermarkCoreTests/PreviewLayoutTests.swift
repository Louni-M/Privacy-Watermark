import Foundation
import Testing
@testable import WatermarkCore

struct PreviewLayoutTests {
    @Test func mixedPagesIntersectionsAndGapTies() throws {
        let layout = PreviewLayout(sizes: [CGSize(width: 600, height: 800), CGSize(width: 900, height: 400),
            CGSize(width: 200, height: 300)], scale: 0.5, viewport: CGSize(width: 600, height: 500))
        #expect(layout.pages[0] == CGRect(x: 150, y: 0, width: 300, height: 400))
        #expect(layout.pages[1] == CGRect(x: 75, y: 416, width: 450, height: 200))
        #expect(layout.pages[2].minY == 632)
        #expect(layout.extent == CGSize(width: 600, height: 782))
        #expect(layout.currentPage(at: CGPoint(x: 0, y: 408)) == 0)
        #expect(layout.currentPage(at: CGPoint(x: 0, y: 409)) == 1)
        let regions = layout.regions(in: CGRect(x: 0, y: 350, width: 600, height: 200))
        #expect(regions[0] == CGRect(x: 0, y: 0, width: 600, height: 100))
        #expect(regions[1] == CGRect(x: 0, y: 132, width: 900, height: 268))
        #expect(regions[2] == nil)
    }

    @Test func anchorsSurviveZoomResizeAndClamp() throws {
        let sizes = [CGSize(width: 600, height: 800), CGSize(width: 900, height: 400)]
        let old = PreviewLayout(sizes: sizes, scale: 0.1, viewport: CGSize(width: 100, height: 100))
        let anchor = try #require(old.anchor(at: CGPoint(x: 50, y: 88)))
        #expect(anchor.page == 0 && anchor.point.y == 800)
        let new = PreviewLayout(sizes: sizes, scale: 0.12, viewport: CGSize(width: 120, height: 100))
        #expect(new.position(of: anchor) == CGPoint(x: 60, y: 96))
        #expect(new.clamped(CGPoint(x: -100, y: 1000), viewport: CGSize(width: 120, height: 100)) == CGPoint(x: 0, y: 60))
        #expect(new.pages[1].minY - new.pages[0].maxY == 16)
    }

    @Test func displayedRotatedPageSizes() throws {
        let source = try SourceDocument.load(Bundle.module.url(forResource: "document.pdf", withExtension: nil, subdirectory: "Fixtures")!)
        let sizes = try PreviewRendering.pageSizes(source)
        #expect(sizes.count == source.pageCount)
        for page in sizes.indices { #expect(try sizes[page] == PreviewRendering.pageSize(source, pageIndex: page)) }
    }
}
