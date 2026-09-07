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

Exports use immutable source bytes and the current settings rather than reusing preview output. Source path and file identity checks reject attempts to overwrite the original, including known symbolic and hard links. Existing output files require replacement confirmation.

Output is staged in a private directory beside the destination, then committed after every page succeeds. Failed commits attempt to restore replaced files. Temporary files are removed on ordinary completion or failure; a crash, forced termination or failed restoration can leave a staging directory for recovery. A filesystem concurrently changed by another process is outside the transactional guarantee.

The app presents safe error messages and does not create a diagnostic file log or record document contents, watermark text or private paths. macOS frameworks may emit their own system diagnostics. The app is ad-hoc signed, not notarized or App Sandbox enabled.

Preview generation and export run through a serial background worker. Settings and document generations prevent outdated work from replacing the latest preview. Failed operations leave the app available for another attempt.

## Reporting a problem

Report reproducible issues through the repository's issue tracker using synthetic examples. Do not attach identity documents, private watermark text or other personal data to a public report.
