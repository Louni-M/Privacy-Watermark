import SwiftUI
import WatermarkCore

struct ContentView: View {
    @Bindable var session: Session
    @State private var adjustmentsExpanded = false

    var body: some View {
        HStack(spacing: 0) {
            controls
                .frame(width: 280)
                .padding(24)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(.regularMaterial)
            Divider()
            preview
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 860, minHeight: 600)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button("Open…", systemImage: "folder") { Task { await session.chooseFile() } }
                    .disabled(session.isExporting)
                    .keyboardShortcut("o")
            }
            ToolbarItem {
                if let document = session.document {
                    Text(document.url.lastPathComponent).foregroundStyle(.secondary).lineLimit(1)
                }
            }
        }
        .alert("Unable to complete operation", isPresented: Binding(
            get: { session.errorMessage != nil },
            set: { if !$0 { session.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { session.errorMessage = nil }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Watermark").font(.title2.weight(.semibold))
                Text("A marked copy. Your original stays yours.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Watermark text").font(.headline)
                TextField("COPY", text: Binding(
                    get: { session.watermark.text },
                    set: { session.watermark.text = String($0.prefix(200)) }
                ))
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("watermarkText")
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
                }.padding(.top, 12)
            }
            Spacer(minLength: 8)
            exportControls
        }
        .disabled(session.document == nil || session.isLoading || session.isExporting)
    }

    private func adjustment(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, suffix: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(Int(value.wrappedValue))\(suffix)").monospacedDigit().foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: 1).accessibilityLabel(title)
        }
    }

    private var exportControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Divider()
            Picker("Export as", selection: $session.exportSettings.format) {
                ForEach(OutputFormat.allCases, id: \.self) { format in
                    Text(session.isPDF && format != .pdf ? "\(format.rawValue) images" : format.rawValue).tag(format)
                }
            }
            if session.isPDF {
                Picker("PDF processing", selection: $session.exportSettings.flattened) {
                    Text("Flattened").tag(true)
                    Text("Selectable text").tag(false)
                }.pickerStyle(.segmented)
                if session.exportSettings.flattened {
                    Picker("Quality", selection: $session.exportSettings.dpi) {
                        ForEach([300, 450, 600], id: \.self) { Text("\($0) DPI").tag($0) }
                    }
                    Text(session.exportAsImages
                         ? "The watermark is combined with the page before image export. Page images keep their original 72 DPI sizing."
                         : "Combines the watermark with the page image. Larger files; text is no longer selectable.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Label("In a PDF, this watermark can be removed separately with an editor.", systemImage: "info.circle")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button {
                Task { await session.chooseDestination() }
            } label: {
                HStack {
                    if session.isExporting { ProgressView().controlSize(.small) }
                    else { Image(systemName: "square.and.arrow.up") }
                    Text(session.isExporting ? "Exporting…" : session.exportAsImages ? "Export page images…" : "Export copy…")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("s", modifiers: [.command, .shift])
            .disabled(!session.canExport)
            .accessibilityIdentifier("exportCopy")
        }
    }

    private var preview: some View {
        VStack(spacing: 16) {
            if let image = session.preview {
                Image(nsImage: image)
                    .resizable().aspectRatio(contentMode: .fit)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .padding(24)
                    .accessibilityLabel("Watermarked document preview")
                HStack(spacing: 8) {
                    if session.isRendering || session.isLoading { ProgressView().controlSize(.small) }
                    Text(session.fileInformation).font(.caption).foregroundStyle(.secondary)
                }
            } else if session.isLoading || session.isRendering {
                Spacer()
                ProgressView("Preparing preview…")
                Spacer()
            } else {
                Spacer()
                Image(systemName: "doc.viewfinder").font(.system(size: 56, weight: .light)).foregroundStyle(.secondary)
                Text("Make a marked copy").font(.title2.weight(.medium))
                Text("Open an image or PDF to get started.").foregroundStyle(.secondary)
                Button("Open document…") { Task { await session.chooseFile() } }.controlSize(.large)
                Text("JPG, PNG, PDF · Processed entirely on your Mac")
                    .font(.caption).foregroundStyle(.tertiary)
                Spacer()
            }
            if !session.status.isEmpty {
                Label(session.status, systemImage: "checkmark.circle.fill")
                    .font(.callout).foregroundStyle(.green)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("exportStatus")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .underPageBackgroundColor))
    }
}
