import AppKit
import SwiftUI
import WatermarkCore

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

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: PreviewScrollView, context: Context) -> CGSize? {
        CGSize(width: proposal.width ?? 0, height: proposal.height ?? 0)
    }

    func updateNSView(_ scroll: PreviewScrollView, context: Context) {
        scroll.session = session
        scroll.refresh()
    }
}

@MainActor final class PreviewScrollView: NSScrollView {
    weak var session: Session?
    private var reset = -1
    private var navigation = -1
    private var zoomRequest = -1
    private var reporting = false
    private var refreshing = false
    private var animation: Task<Void, Never>?
    private var pointerAnchor: CGPoint?
    private var geometry = PreviewLayout(sizes: [], scale: 1, viewport: .zero)

    override func layout() {
        super.layout()
        refresh()
    }

    func refresh() {
        guard !refreshing, let session, let canvas = documentView as? PreviewCanvas else { return }
        refreshing = true
        defer { refreshing = false }
        let viewport = contentView.bounds.size
        let pendingNavigation = navigation != session.navigationRevision
        let oldScale = geometry.scale
        let targetScale = session.zoom ?? session.fitScale
        if pendingNavigation && navigation >= 0 && !geometry.pages.isEmpty && session.zoom == nil {
            session.setTransitionScale(oldScale)
        }
        let screenAnchor = pointerAnchor ?? CGPoint(x: viewport.width / 2, y: viewport.height / 2)
        let oldOrigin = contentView.bounds.origin
        let anchor = geometry.anchor(at: CGPoint(x: oldOrigin.x + screenAnchor.x, y: oldOrigin.y + screenAnchor.y))
        let next = PreviewLayout(sizes: session.pageSizes, scale: session.effectiveScale, viewport: viewport)
        let changed = next != geometry
        geometry = next
        canvas.geometry = next
        canvas.session = session
        if canvas.frame.size != next.extent { canvas.setFrameSize(next.extent) }
        canvas.needsDisplay = true
        if reset != session.viewReset {
            animation?.cancel()
            reset = session.viewReset
            if next.pages.indices.contains(session.pageIndex) { scrollToPage(session.pageIndex) }
            else { move(to: .zero) }
        } else if changed, let anchor {
            let position = next.position(of: anchor)
            move(to: CGPoint(x: position.x - screenAnchor.x, y: position.y - screenAnchor.y))
        }
        if navigation != session.navigationRevision {
            navigation = session.navigationRevision
            let target = session.navigationTarget
            if next.pages.indices.contains(target) { animatePage(target, targetScale: targetScale) }
        }
        if zoomRequest != session.zoomRequestRevision {
            let initial = zoomRequest == -1
            zoomRequest = session.zoomRequestRevision
            if !initial { animateZoom(to: session.zoomRequest) }
        }
        report()
    }

    private func move(to origin: CGPoint) {
        contentView.scroll(to: geometry.clamped(origin, viewport: contentView.bounds.size))
        reflectScrolledClipView(contentView)
    }

    private func pageOrigin(_ page: Int) -> CGPoint {
        let rect = geometry.pages[page]
        return CGPoint(x: max(0, rect.midX - contentView.bounds.width / 2),
            y: rect.minY - max(0, (contentView.bounds.height - rect.height) / 2))
    }

    private func scrollToPage(_ page: Int) { move(to: pageOrigin(page)) }

    private func animate(_ step: @escaping @MainActor (CGFloat) -> Void, completion: @escaping @MainActor () -> Void = {}) {
        animation?.cancel()
        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            step(1); completion(); return
        }
        animation = Task { @MainActor in
            let start = ContinuousClock.now
            while !Task.isCancelled {
                let elapsed = start.duration(to: .now)
                let seconds = Double(elapsed.components.seconds) + Double(elapsed.components.attoseconds) / 1e18
                let fraction = min(1, seconds / 0.18)
                let eased = CGFloat(fraction * fraction * (3 - 2 * fraction))
                step(eased)
                if fraction >= 1 { completion(); return }
                do { try await Task.sleep(for: .milliseconds(8)) } catch { return }
            }
        }
    }

    private func animatePage(_ page: Int, targetScale: CGFloat) {
        guard let session else { return }
        let start = contentView.bounds.origin
        let startScale = geometry.scale
        let endLayout = PreviewLayout(sizes: session.pageSizes, scale: targetScale, viewport: contentView.bounds.size)
        let rect = endLayout.pages[page]
        let end = endLayout.clamped(CGPoint(x: rect.midX - contentView.bounds.width / 2,
            y: rect.minY - max(0, (contentView.bounds.height - rect.height) / 2)), viewport: contentView.bounds.size)
        animate { [weak self, weak session] t in
            guard let self, let session else { return }
            if session.zoom == nil {
                session.setTransitionScale(exp(log(startScale) + (log(targetScale) - log(startScale)) * t))
                self.refresh()
            }
            self.move(to: CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t))
            self.report()
        } completion: { [weak session] in session?.setTransitionScale(nil) }
    }

    private func animateZoom(to requested: CGFloat?) {
        guard let session else { return }
        if requested == nil {
            let start = session.effectiveScale
            session.setZoom(nil)
            // Keep the visible scale until the page transition takes over.
            session.setTransitionScale(start)
            reset = session.viewReset
            refresh()
            return
        }
        let start = session.effectiveScale
        let page = session.pageIndex
        let size = session.pageSizes.indices.contains(page) ? session.pageSizes[page] : session.pageSize
        let fit = min(contentView.bounds.width / size.width, contentView.bounds.height / size.height)
        let end = requested.map { session.boundedZoom($0) } ?? fit
        animate { [weak self, weak session] t in
            guard let self, let session else { return }
            session.setZoom(exp(log(start) + (log(end) - log(start)) * t))
            self.refresh()
        } completion: { [weak self, weak session] in
            if requested == nil { session?.setZoom(nil); self?.refresh() }
        }
    }

    override func scrollWheel(with event: NSEvent) {
        interruptAnimation()
        if event.modifierFlags.contains(.command) {
            zoom(by: exp(event.scrollingDeltaY * 0.01), event: event)
        } else {
            super.scrollWheel(with: event)
        }
    }

    override func magnify(with event: NSEvent) {
        interruptAnimation()
        zoom(by: max(0.01, 1 + event.magnification), event: event)
    }

    private func interruptAnimation() {
        animation?.cancel()
    }

    override func mouseDown(with event: NSEvent) {
        interruptAnimation()
        super.mouseDown(with: event)
    }

    private func zoom(by factor: CGFloat, event: NSEvent) {
        guard let session else { return }
        let point = contentView.convert(event.locationInWindow, from: nil)
        pointerAnchor = CGPoint(x: point.x - contentView.bounds.minX, y: point.y - contentView.bounds.minY)
        session.setZoom(session.effectiveScale * factor)
        refresh()
        pointerAnchor = nil
    }

    @objc func boundsChanged(_ notification: Notification) { report() }

    private func report() {
        guard !reporting else { return }
        reporting = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            reporting = false
            guard let session else { return }
            let view = contentView.bounds
            session.updateViewport(size: view.size, regions: geometry.regions(in: view), origin: view.origin,
                currentPage: geometry.currentPage(at: CGPoint(x: view.midX, y: view.midY)) ?? 0,
                backingScale: window?.backingScaleFactor ?? 1)
        }
    }
}

@MainActor final class PreviewCanvas: NSView {
    weak var session: Session?
    var geometry = PreviewLayout(sizes: [], scale: 1, viewport: .zero)
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let session else { return }
        for (page, rect) in geometry.pages.enumerated() where rect.intersects(dirtyRect) {
            NSColor.white.setFill()
            rect.fill()
            if let overview = session.overviews[page] { draw(overview, page: page) }
            if let detail = session.details[page] { draw(detail, page: page) }
            if session.overviews[page] == nil && session.details[page] == nil {
                ("Loading page \(page + 1)…" as NSString).draw(at: CGPoint(x: rect.minX + 12, y: rect.minY + 12),
                    withAttributes: [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 13)])
            }
        }
    }

    private func draw(_ entry: Session.PageImage, page: Int) {
        let region = entry.key.viewport.region
        let pageRect = geometry.pages[page]
        let rect = CGRect(x: pageRect.minX + region.minX * geometry.scale,
            y: pageRect.minY + (geometry.sizes[page].height - region.maxY) * geometry.scale,
            width: region.width * geometry.scale, height: region.height * geometry.scale)
        entry.image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
    }
}
