import SwiftUI
import WatermarkCore

struct LocalProcessingNote: View {
    var body: some View {
        Text("Processed on your Mac. Originals stay unchanged.")
            .font(.callout).foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

enum AppearanceNumber {
    static func commit(_ draft: String, previous: Double, range: ClosedRange<Double>, locale: Locale = .current) -> Double {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let decimal = NSRegularExpression.escapedPattern(for: locale.decimalSeparator ?? ".")
        let grouping = NSRegularExpression.escapedPattern(for: locale.groupingSeparator ?? ",")
        let integer = "(?:[0-9]+|[0-9]{1,3}(?:\(grouping)[0-9]{3})+)"
        let pattern = "^[+-]?(?:\(integer)(?:\(decimal)[0-9]*)?|\(decimal)[0-9]+)$"
        guard text.range(of: pattern, options: .regularExpression) != nil else { return previous }
        guard let parsed = try? Double(text, format: .number.locale(locale)), parsed.isFinite else { return previous }
        return min(range.upperBound, max(range.lowerBound, parsed))
    }

    static func display(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

struct AppearanceAdjustment: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var suffix = ""
    @State private var draft = ""
    @FocusState private var focused: Bool

    private func commit() {
        value = AppearanceNumber.commit(draft, previous: value, range: range)
        draft = AppearanceNumber.display(value)
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                TextField(title, text: $draft)
                    .textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing)
                    .frame(width: 68).focused($focused)
                    .accessibilityLabel("\(title) value")
                    .onSubmit { commit() }
                    .onChange(of: focused) { _, active in if !active { commit() } }
                if !suffix.isEmpty { Text(suffix) }
            }
            AppearanceSlider(value: $value, range: range, title: title).frame(height: 22)
        }
        .onAppear { draft = AppearanceNumber.display(value) }
        .onChange(of: value) { _, newValue in draft = AppearanceNumber.display(newValue) }
    }
}

// Keep native tracking, keyboard controls, accessibility and thumb rendering.
private final class BlackTrackSliderCell: NSSliderCell {
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        let track = NSRect(x: rect.minX, y: rect.midY - 3, width: rect.width, height: 6)
        let path = NSBezierPath(roundedRect: track, xRadius: 3, yRadius: 3)
        NSColor.black.setFill()
        path.fill()
        NSGraphicsContext.saveGraphicsState()
        path.addClip()
        let end = knobRect(flipped: flipped).midX
        NSColor.systemBlue.withAlphaComponent(isEnabled ? 1 : 0.4).setFill()
        NSRect(x: track.minX, y: track.minY,
               width: max(0, min(track.width, end - track.minX)), height: track.height).fill()
        NSGraphicsContext.restoreGraphicsState()
    }
}

private final class FocusableAppearanceSlider: NSSlider {
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        super.mouseDown(with: event)
    }
}

private struct AppearanceSlider: NSViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let title: String
    @Environment(\.isEnabled) private var isEnabled

    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }

    func makeNSView(context: Context) -> NSSlider {
        let slider = FocusableAppearanceSlider()
        slider.cell = BlackTrackSliderCell()
        slider.isContinuous = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.changed(_:))
        slider.setContentHuggingPriority(.defaultLow, for: .horizontal)
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
        @MainActor @objc func changed(_ slider: NSSlider) { value.wrappedValue = slider.doubleValue }
    }
}

struct SamplePreview: View {
    let watermark: WatermarkSettings
    let targeted: Bool
    let addFiles: () -> Void
    @State private var image: NSImage?
    @State private var renderFailed = false

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 6) {
                Text("Make marked copies").font(.title2.weight(.semibold))
                Text("Add or drop JPG, PNG and PDF files.")
                    .font(.callout).foregroundStyle(.secondary)
                Button("Add files…", systemImage: "plus") { addFiles() }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .accessibilityIdentifier("emptyAddFiles")
            }
            .padding(18).frame(maxWidth: .infinity)
            .background(targeted ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(
                targeted ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: targeted ? 2 : 1, dash: [6, 4])))
            Text("Sample preview").font(.headline).accessibilityIdentifier("sampleLabel")
            if let image {
                Image(nsImage: image).resizable().scaledToFit()
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                    .accessibilityLabel("Fictional document showing your watermark")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if renderFailed {
                Text("Sample preview unavailable. You can still add your documents.")
                    .font(.callout).frame(maxHeight: .infinity)
            } else {
                ProgressView("Preparing sample…").frame(maxHeight: .infinity)
            }
            LocalProcessingNote().multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: watermark) {
            do {
                try await Task.sleep(for: .milliseconds(100))
                let settings = watermark
                let bytes = try await Task.detached(priority: .userInitiated) {
                    try SampleDocument.render(watermark: settings)
                }.value
                try Task.checkCancellation()
                image = NSImage(data: bytes)
                renderFailed = image == nil
            } catch is CancellationError {
                // A newer settings snapshot or a real document now owns the view.
            } catch { image = nil; renderFailed = true }
        }
    }
}
