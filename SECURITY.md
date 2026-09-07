# Security and privacy

Passport Filigrane processes documents locally using macOS frameworks. It has no account, upload service, telemetry or application network client. Keep macOS updated to receive fixes to its image and PDF parsers.

## What watermarking protects

Flattened PDF output, the default at 450 DPI, combines each page and watermark into an image. The generated PDF contains no separate watermark or embedded selectable source-text layer. Image editing and later OCR remain possible; watermarking is not encryption, redaction or a guarantee against removal.

Selectable-text PDF output retains visible source content and vector text, with the watermark as separate editable text. It is not a general PDF sanitization feature. Visible annotations and form appearances are retained; the app is not a form editor.

Image exports and newly encoded images in flattened/image PDFs discard source EXIF, GPS, camera and timestamp metadata. Visible information in the document remains visible. Transparent inputs become opaque, matching the existing export behavior.

## Input and resource limits

- Accepted extensions: case-insensitive JPG, JPEG, PNG and PDF, followed by decoder validation.
- Maximum input size: 100 MiB, checked before and after reading.
- Maximum PDF pages: 50, checked after parsing; encrypted and empty PDFs are rejected.
- Maximum image dimensions: 20,000 pixels per side, checked before full decoding.

These limits reduce resource use but do not make arbitrary files safe or guarantee that every large document fits in memory. Flattened PDF rendering processes one page at a time; unusually large page dimensions or high DPI can still require substantial memory.

## Files and diagnostics

Exports use immutable source bytes and a snapshot of shared settings rather than reusing preview output. Rows retain metadata and SHA-256 content fingerprints, not every decoded document. Reuse verifies identity and content, with checks across the read. Changed or unreadable sources require re-addition; the app does not silently substitute new content. Filesystem identity deduplicates symbolic/hard links while keeping distinct, content-identical files.

Each input is staged in a private directory beside the destination. After every page succeeds, an exclusive filesystem rename publishes the complete file or whole page-series folder. Existing files, directories and batch sources are never replaced. A competing writer taking a name causes allocation of the next numeric suffix without re-rendering. Unfinished staging is removed on normal failure or cancellation; completed copies remain. A crash or forced termination can leave a private `.passport-batch-…` or `.passport-export-…` staging directory; persistent crash recovery is not implemented.

The app presents safe error messages and does not create a diagnostic file log or record document contents, watermark text or private paths. macOS frameworks may emit their own system diagnostics. The app is ad-hoc signed, not notarized or App Sandbox enabled.

Progressive validation and sequential export are separate from the interactive preview worker. Only active operations retain full sources. Preview requests identify the item, fingerprint, page, settings revision and viewport; cancelled or stale requests cannot replace the current view. The preview cache has a 96-MiB budget and rendered preview buffers are capped at 16 megapixels. Large zoom requests render the visible region with bounded scratch buffers. Export still renders full-resolution pages and can require substantial memory. Cancellation is cooperative between safe processing boundaries; system decoding may finish before cancellation completes. Failed operations leave the app available for another attempt.

## Reporting a problem

Report reproducible issues through the repository's issue tracker using synthetic examples. Do not attach identity documents, private watermark text or other personal data to a public report.
