import SwiftUI
import WatermarkCore

struct ContentView: View {
    @Bindable var session: Session
    @State private var adjustmentsExpanded = false
    @State private var dateLine = WatermarkText.dateLine(for: Date())
    @State private var dropTargeted = false

    init(session: Session, adjustmentsExpanded: Bool = false) {
        self.session = session
        _adjustmentsExpanded = State(initialValue: adjustmentsExpanded)
    }

    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                VStack(spacing: 0) {
                    ScrollView { controls.padding(16) }
                    Divider()
                    exportAction.padding(16)
                }
                .frame(minWidth: 260, idealWidth: 280,
                       maxWidth: max(280, geometry.size.width - (session.batch.items.isEmpty ? 321 : 512)))
                .background(.regularMaterial)
                HStack(spacing: 0) {
                    if !session.batch.items.isEmpty {
                        fileList.frame(width: 190)
                        Divider()
                    }
                    preview.frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
                }
                .layoutPriority(1)
            }
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
        } isTargeted: { dropTargeted = $0 }
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
                            .font(.callout).foregroundStyle(.secondary).lineLimit(2)
                            .help(item.url.path)
                        Text(rowStatus(item)).font(.callout).foregroundStyle(rowFailed(item) ? .red : .secondary)
                        Button("Remove", systemImage: "minus.circle") { session.remove(item.id) }
                            .buttonStyle(.borderless).font(.callout).disabled(session.isExporting)
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
                Text(session.feedback).font(.callout).foregroundStyle(.secondary).padding(8)
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
                TextEditor(text: Binding(
                    get: { session.watermark.text },
                    set: { session.watermark.text = WatermarkText.accepted($0) }
                ))
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(6)
                .frame(height: 82)
                .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
                .accessibilityLabel("Watermark text")
                .accessibilityIdentifier("watermarkText")
                Text("\(session.watermark.text.count) / \(WatermarkText.limit) characters")
                    .font(.callout).foregroundStyle(.secondary)
                Toggle("Include today’s date", isOn: Binding(
                    get: { WatermarkText.containsDateLine(dateLine, in: session.watermark.text) },
                    set: { include in
                        if include { dateLine = WatermarkText.dateLine(for: Date()) }
                        session.watermark.text = WatermarkText.settingDateLine(
                            dateLine, included: include, in: session.watermark.text)
                    }
                ))
                .toggleStyle(.checkbox)
                .accessibilityIdentifier("includeTodayDate")
                .keyboardShortcut("d", modifiers: [.command, .shift])
            }
            DisclosureGroup("Appearance", isExpanded: $adjustmentsExpanded) {
                VStack(spacing: 16) {
                    AppearanceAdjustment(title: "Opacity", value: $session.watermark.opacity, range: 0...100, suffix: "%")
                    AppearanceAdjustment(title: "Text size", value: $session.watermark.size, range: 12...72)
                    AppearanceAdjustment(title: "Spacing", value: $session.watermark.spacing, range: 50...300)
                    Text("Size and spacing scale with your document. Longer text gets extra room to avoid overlap.")
                        .font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Picker("Color", selection: $session.watermark.color) {
                        ForEach(WatermarkColor.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Direction", selection: $session.watermark.direction) {
                        ForEach(WatermarkDirection.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Button("Reset appearance") { session.resetAppearance() }
                        .accessibilityIdentifier("resetAppearance")
                        .keyboardShortcut("r", modifiers: [.command, .shift])
                }
                .pickerStyle(.menu)
                .buttonStyle(.borderless)
                .padding(.top, 12)
            }
            .disclosureGroupStyle(AppearanceDisclosureStyle())
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                Text("Export as").font(.headline)
                Picker("Export as", selection: $session.outputPolicy) {
                    ForEach(OutputPolicy.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.labelsHidden().frame(maxWidth: .infinity)
            }
            if session.hasPDFOutput {
                Picker("PDF processing", selection: $session.exportSettings.flattened) {
                    Text("Flattened").tag(true)
                    Text("Selectable text").tag(false)
                }
                if session.exportSettings.flattened {
                    Picker("Quality", selection: $session.exportSettings.dpi) {
                        ForEach([300, 450, 600], id: \.self) { Text("\($0) DPI").tag($0) }
                    }
                    Text("Combines the watermark with the page image. Ordinary text selection is lost.")
                        .font(.callout).foregroundStyle(.secondary)
                } else {
                    Text("In a PDF, this watermark can be removed separately with an editor.")
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
            if session.hasPDFPageImages {
                Text("PDF pages export as images at 72 DPI.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Text(session.exportPrediction.message)
                .font(.callout).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("exportPrediction")
            LocalProcessingNote()
        }.disabled(session.isExporting)
    }

    private var exportAction: some View {
        VStack(alignment: .leading, spacing: 8) {
            if session.isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: Double(session.completedFiles), total: Double(max(1, session.totalFiles)))
                    HStack {
                        Text(session.isCancelling ? "Cancelling…" : "\(session.completedFiles) of \(session.totalFiles) files")
                        Spacer()
                        Button("Cancel") { session.cancelExport() }.disabled(session.isCancelling)
                    }
                }
            } else {
                Button(session.exportPrediction.actionLabel, systemImage: "square.and.arrow.up") {
                    Task { await session.chooseDestination() }
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                .disabled(!session.canExport).accessibilityIdentifier("exportAll")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        Text(session.fileInformation).font(.callout).monospacedDigit()
                        Button("Next page", systemImage: "chevron.right") { session.changePage(1) }
                            .labelStyle(.iconOnly).disabled(session.pageIndex + 1 >= session.pageCount)
                    } else { Text(session.fileInformation).font(.callout) }
                    Spacer(minLength: 0)
                }
                HStack {
                    Button("Zoom out", systemImage: "minus.magnifyingglass") { session.requestZoom(session.effectiveScale / 1.2) }
                        .labelStyle(.iconOnly).disabled(session.effectiveScale <= session.minimumZoom)
                    Text("\(Int(session.effectiveScale * 100))%").font(.callout).monospacedDigit()
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
            } else if session.batch.items.isEmpty {
                SamplePreview(watermark: session.watermark, targeted: dropTargeted) {
                    Task { await session.chooseFiles() }
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
            .keyboardShortcut("a", modifiers: [.command, .shift])
            if configuration.isExpanded { configuration.content }
        }
    }
}

private extension URL {
    var abbreviatingWithTildeInPath: String { (path as NSString).abbreviatingWithTildeInPath }
}
