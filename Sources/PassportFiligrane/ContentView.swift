import SwiftUI
import WatermarkCore

struct ContentView: View {
    @Bindable var session: Session
    @State private var adjustmentsExpanded = false

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                controls.padding(16)
            }
            .frame(width: 240)
            .background(.regularMaterial)
            Divider()
            fileList.frame(width: 190)
            Divider()
            preview.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Add files…", systemImage: "plus") { Task { await session.chooseFiles() } }
                    .disabled(session.isExporting).keyboardShortcut("o")
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !session.isExporting else { return false }
            session.add(urls)
            return true
        }
        .alert("Unable to complete operation", isPresented: Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.errorMessage = nil } }
        )) { Button("OK", role: .cancel) { session.errorMessage = nil } }
        message: { Text(session.errorMessage ?? "") }
    }

    private var fileList: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Files (\(session.batch.items.count))").font(.headline)
                Spacer()
                Button("Clear all") { session.clearAll() }
                    .buttonStyle(.borderless)
                    .disabled(session.isExporting || session.batch.items.isEmpty)
            }.padding([.horizontal, .top], 12)
            List(selection: Binding(
                get: { session.batch.selectedID },
                set: { if let id = $0 { session.select(id) } }
            )) {
                ForEach(session.batch.items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Label(item.url.lastPathComponent, systemImage: item.url.pathExtension.lowercased() == "pdf" ? "doc.richtext" : "photo")
                            .lineLimit(2)
                        Text(item.url.deletingLastPathComponent().abbreviatingWithTildeInPath)
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(2)
                            .help(item.url.path)
                        Text(rowStatus(item)).font(.caption).foregroundStyle(rowFailed(item) ? .red : .secondary)
                        Button("Remove", systemImage: "minus.circle") { session.remove(item.id) }
                            .buttonStyle(.borderless).font(.caption).disabled(session.isExporting)
                    }.padding(.vertical, 4).tag(item.id)
                }
            }
            .onDeleteCommand {
                if let id = session.batch.selectedID { session.remove(id) }
            }
            if session.isLoading {
                ProgressView("Checking \(session.batch.checkingCount) files…").controlSize(.small).padding(8)
            }
            if !session.feedback.isEmpty {
                Text(session.feedback).font(.caption).foregroundStyle(.secondary).padding(8)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func rowFailed(_ item: BatchItem) -> Bool {
        if case .invalid = item.validation { return true }
        if case .failed = item.export { return true }
        return false
    }

    private func rowStatus(_ item: BatchItem) -> String {
        switch item.validation {
        case .checking: return "Checking…"
        case .invalid(let message): return message
        case .ready: break
        }
        switch item.export {
        case .idle: return "Ready"
        case .pending: return "Waiting to export"
        case .exporting: return "Exporting…"
        case .saved: return "Saved"
        case .failed(let message): return message
        case .unprocessed: return "Not processed"
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Watermark").font(.title2.weight(.semibold))
            Text("Shared settings · All files").font(.callout).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Text("Watermark text").font(.headline)
                TextField("COPY", text: Binding(
                    get: { session.watermark.text },
                    set: { session.watermark.text = String($0.prefix(200)) }
                )).textFieldStyle(.roundedBorder).accessibilityIdentifier("watermarkText")
            }
            DisclosureGroup("Appearance", isExpanded: $adjustmentsExpanded) {
                VStack(spacing: 16) {
                    adjustment("Opacity", value: $session.watermark.opacity, range: 0...100, suffix: "%")
                    adjustment("Text size", value: $session.watermark.size, range: 12...72, suffix: "")
                    adjustment("Spacing", value: $session.watermark.spacing, range: 50...300, suffix: "")
                    Picker("Color", selection: $session.watermark.color) {
                        ForEach(WatermarkColor.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Direction", selection: $session.watermark.direction) {
                        ForEach(WatermarkDirection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                }
                .pickerStyle(.menu)
                .buttonStyle(.borderless)
                .padding(.top, 12)
            }
            .disclosureGroupStyle(AppearanceDisclosureStyle())
            Divider()
            Picker("Export as", selection: $session.outputPolicy) {
                ForEach(OutputPolicy.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            if session.hasPDF {
                Picker("PDF processing", selection: $session.exportSettings.flattened) {
                    Text("Flattened").tag(true)
                    Text("Selectable text").tag(false)
                }
                if session.exportSettings.flattened {
                    Picker("Quality", selection: $session.exportSettings.dpi) {
                        ForEach([300, 450, 600], id: \.self) { Text("\($0) DPI").tag($0) }
                    }
                    Text("Combines the watermark with the page image. PDF page images export at 72 DPI.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("In a PDF, this watermark can be removed separately with an editor.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("Export all…", systemImage: "square.and.arrow.up") {
                Task { await session.chooseDestination() }
            }
            .buttonStyle(.borderedProminent).controlSize(.large)
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(!session.canExport).accessibilityIdentifier("exportAll")
            Text("Original files stay unchanged.").font(.caption).foregroundStyle(.secondary)
        }.disabled(session.isExporting)
    }

    private func adjustment(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))\(suffix)").monospacedDigit().foregroundStyle(.secondary)
            }
            BlackTrackSlider(value: value, range: range, title: title)
                .frame(height: 20)
        }
    }

    private var preview: some View {
        VStack(spacing: 12) {
            if let name = session.selected?.url.lastPathComponent {
                Text(name)
                    .font(.headline)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .help(name)
                    .accessibilityLabel(name)
                    .accessibilityIdentifier("selectedFilename")
            }
            if session.selected?.validation.metadata != nil {
                HStack {
                    if session.isPDF {
                        Button("Previous page", systemImage: "chevron.left") { session.changePage(-1) }
                            .labelStyle(.iconOnly).disabled(session.pageIndex == 0)
                        Text(session.fileInformation).font(.caption).monospacedDigit()
                        Button("Next page", systemImage: "chevron.right") { session.changePage(1) }
                            .labelStyle(.iconOnly).disabled(session.pageIndex + 1 >= session.pageCount)
                    } else { Text(session.fileInformation).font(.caption) }
                    Spacer(minLength: 0)
                }
                HStack {
                    Button("Zoom out", systemImage: "minus.magnifyingglass") { session.requestZoom(session.effectiveScale / 1.2) }
                        .labelStyle(.iconOnly).disabled(session.effectiveScale <= session.minimumZoom)
                    Text("\(Int(session.effectiveScale * 100))%").font(.caption).monospacedDigit()
                    Button("Zoom in", systemImage: "plus.magnifyingglass") { session.requestZoom(session.effectiveScale * 1.2) }
                        .labelStyle(.iconOnly).disabled(session.effectiveScale >= 4)
                    Button("Fit to window") { session.requestZoom(nil) }
                    Spacer(minLength: 0)
                }
                PreviewHost(session: session)
                    .accessibilityLabel("Watermarked document preview")
                    .overlay(alignment: .topTrailing) {
                        if session.isRendering {
                            ProgressView("Updating…").controlSize(.small).padding(8).background(.regularMaterial)
                        }
                    }
            } else {
                Spacer()
                Image(systemName: "doc.viewfinder").font(.system(size: 48, weight: .light)).foregroundStyle(.secondary)
                if let selected = session.selected {
                    Text(rowStatus(selected)).multilineTextAlignment(.center)
                } else {
                    Text("Make marked copies").font(.title2)
                    Text("Add or drop JPG, PNG and PDF files.").foregroundStyle(.secondary)
                    Button("Add files…") { Task { await session.chooseFiles() } }
                }
                Spacer()
            }
            if session.isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: Double(session.completedFiles), total: Double(max(1, session.totalFiles)))
                    HStack {
                        Text(session.isCancelling ? "Cancelling…" : "\(session.completedFiles) of \(session.totalFiles) files")
                        Spacer()
                        Button("Cancel") { session.cancelExport() }.disabled(session.isCancelling)
                    }
                }
            }
            if !session.status.isEmpty {
                Text(session.status).font(.callout).textSelection(.enabled).accessibilityIdentifier("exportStatus")
                if session.canRevealExports {
                    Button("Reveal in Finder", systemImage: "folder") { session.revealExports() }
                        .buttonStyle(.bordered)
                        .help("Show the files saved by the latest export in Finder.")
                        .accessibilityIdentifier("revealExports")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct BlackTrackSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let title: String
    @Environment(\.isEnabled) private var isEnabled

    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }

    func makeNSView(context: Context) -> NSSlider {
        let slider = NSSlider()
        slider.cell = BlackTrackSliderCell()
        slider.isContinuous = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.changed(_:))
        return slider
    }

    func updateNSView(_ slider: NSSlider, context: Context) {
        context.coordinator.value = $value
        slider.minValue = range.lowerBound
        slider.maxValue = range.upperBound
        slider.doubleValue = value
        slider.isEnabled = isEnabled
        slider.setAccessibilityLabel(title)
        slider.needsDisplay = true
    }

    final class Coordinator: NSObject {
        var value: Binding<Double>

        init(value: Binding<Double>) { self.value = value }

        @MainActor @objc func changed(_ slider: NSSlider) {
            let rounded = slider.doubleValue.rounded()
            slider.doubleValue = rounded
            value.wrappedValue = rounded
        }
    }
}

private final class BlackTrackSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let track = NSRect(x: rect.minX, y: rect.midY - 2, width: rect.width, height: 4)
        let path = NSBezierPath(roundedRect: track, xRadius: 2, yRadius: 2)
        NSColor.black.setFill()
        path.fill()

        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let filledWidth = min(track.width, max(0, knobRect(flipped: flipped).midX - track.minX))
        NSColor.controlAccentColor.withAlphaComponent(isEnabled ? 1 : 0.4).setFill()
        NSBezierPath(rect: NSRect(x: track.minX, y: track.minY, width: filledWidth, height: track.height)).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

private struct AppearanceDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation { configuration.isExpanded.toggle() }
            } label: {
                HStack {
                    configuration.label
                    Spacer()
                    Image(systemName: configuration.isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, minHeight: 28)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityValue(configuration.isExpanded ? "Expanded" : "Collapsed")
            .accessibilityIdentifier("appearanceToggle")
            if configuration.isExpanded { configuration.content }
        }
    }
}

private extension URL {
    var abbreviatingWithTildeInPath: String { (path as NSString).abbreviatingWithTildeInPath }
}
