import AppKit
import SwiftUI

struct PreviewHost: NSViewRepresentable {
    let session: Session

    func makeNSView(context: Context) -> PreviewScrollView {
        let scroll = PreviewScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.documentView = PreviewCanvas()
        scroll.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(scroll, selector: #selector(PreviewScrollView.boundsChanged),
            name: NSView.boundsDidChangeNotification, object: scroll.contentView)
        return scroll
    }

    func updateNSView(_ scroll: PreviewScrollView, context: Context) {
        scroll.session = session
        scroll.refresh()
    }
}

@MainActor final class PreviewScrollView: NSScrollView {
    weak var session: Session?
    private var reset = -1
    private var reporting = false

    override func layout() {
        super.layout()
        refresh()
    }

    func refresh() {
        guard let session, let canvas = documentView as? PreviewCanvas else { return }
        let visible = contentView.bounds.size
        let scale = session.effectiveScale
        let size = session.pageSize
        canvas.scale = scale
        canvas.pageSize = size
        canvas.image = session.preview
        canvas.region = session.previewRegion
        let frameSize = CGSize(width: max(visible.width, size.width * scale),
            height: max(visible.height, size.height * scale))
        if canvas.frame.size != frameSize { canvas.setFrameSize(frameSize) }
        canvas.needsDisplay = true
        if reset != session.viewReset {
            reset = session.viewReset
            contentView.scroll(to: .zero)
            reflectScrolledClipView(contentView)
        }
        report()
    }

    @objc func boundsChanged(_ notification: Notification) { report() }

    private func report() {
        guard !reporting else { return }
        reporting = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            reporting = false
            guard let session, let canvas = documentView as? PreviewCanvas else { return }
            let view = contentView.bounds
            let document = canvas.pageRect
            let visible = view.intersection(document)
            let region: CGRect? = document.isEmpty || visible.isNull ? nil : CGRect(
                x: (visible.minX - document.minX) / canvas.scale,
                y: session.pageSize.height - (visible.maxY - document.minY) / canvas.scale,
                width: visible.width / canvas.scale, height: visible.height / canvas.scale)
            session.updateViewport(size: view.size, region: region, backingScale: window?.backingScaleFactor ?? 1)
        }
    }
}

@MainActor final class PreviewCanvas: NSView {
    var image: NSImage?
    var scale: CGFloat = 1
    var pageSize = CGSize.zero
    var region = CGRect.zero
    override var isFlipped: Bool { true }
    var pageRect: CGRect {
        let size = CGSize(width: pageSize.width * scale, height: pageSize.height * scale)
        return CGRect(x: max(0, (bounds.width - size.width) / 2),
            y: max(0, (bounds.height - size.height) / 2), width: size.width, height: size.height)
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill()
        pageRect.fill()
        guard let image else { return }
        let rect = CGRect(x: pageRect.minX + region.minX * scale,
            y: pageRect.minY + (pageSize.height - region.maxY) * scale,
            width: region.width * scale, height: region.height * scale)
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
}
