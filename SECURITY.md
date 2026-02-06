# Security Policy 

This document describes the security measures implemented in Passport Filigrane,
known limitations, and guidelines for users.

## Table of Contents

1. [Dependency Security](#dependency-security)
2. [Input Validation](#input-validation)
3. [File Handling & Privacy](#file-handling--privacy)
4. [Error Logging](#error-logging)
5. [Thread Safety](#thread-safety)
6. [Watermark Security Model](#watermark-security-model)

---

## Dependency Security

### Pinned Versions

All dependencies are pinned to minimum versions that address known CVEs:

| Package | Minimum Version | Rationale |
|---------|----------------|-----------|
| `pillow` | `>=10.3.0` | Fixes CVE-2023-50447 (CRITICAL, CVSS 9.0, arbitrary code execution) and CVE-2024-28219 (HIGH, CVSS 8.1, buffer overflow) |
| `pymupdf` | `>=1.25.0` | Mitigates inherited MuPDF DoS vulnerabilities (CVE-2024-46657) |
| `pyinstaller` | `>=6.0.0` | Fixes CVE-2025-59042 (HIGH, CVSS 7.0, arbitrary code injection via sys.path) |
| `flet` | `==0.21.2` | No known CVEs. Pinned for compatibility; upgrade planned. |

### Updating Dependencies

When updating dependencies:

1. Check for new CVEs at [Snyk Vulnerability DB](https://security.snyk.io/)
2. Run `pip audit` (install with `pip install pip-audit`) to scan for known issues
3. Test thoroughly after any update -- PyMuPDF and Pillow are C-extension libraries
   where version changes can alter behavior

### Future Work

- Migrate from `flet==0.21.2` to the latest stable release (0.80.x+). This is a
  breaking change that requires a code migration.

---

## Input Validation

The application enforces the following limits to prevent resource exhaustion and
denial-of-service conditions:

| Limit | Value | Defined In |
|-------|-------|------------|
| Maximum file size | 100 MB | `main.py` -- `MAX_FILE_SIZE_BYTES` |
| Maximum PDF pages | 50 | `main.py` -- `MAX_PDF_PAGES` |
| Maximum image dimension | 20,000 px per side | `main.py` -- `MAX_IMAGE_DIMENSION` |

These limits are checked **before** the file is loaded into memory or processed.

### Why These Limits Exist

- **File size**: Loading a multi-GB file into memory can crash the application
  or the system.
- **Page count**: In secure raster mode, each page is rendered at up to 600 DPI.
  A 50-page PDF at 600 DPI generates ~50 images of ~6600x4950 pixels each.
- **Image dimension**: Pillow can consume excessive memory for very large images
  (e.g., a 100,000 x 100,000 px image would require ~30 GB of RAM).

### PDF-Specific Risks

PyMuPDF wraps the MuPDF C library. Maliciously crafted PDF files can trigger:
- Segmentation faults (CVE-2024-46657)
- Infinite recursion (CVE-2023-31794)
- Divide-by-zero exceptions

These are DoS vectors, not code execution. The input size limits reduce exposure,
but cannot fully prevent exploitation via crafted files. Keep PyMuPDF updated.

---

## File Handling & Privacy

### EXIF Metadata Stripping

When the user exports watermarked images (JPEG), all EXIF metadata is stripped
from the output. This prevents leaking:

- GPS coordinates (where the photo was taken)
- Camera/phone model and serial number
- Timestamps
- Software identifiers

**Implementation**: `strip_image_metadata()` in `main.py` creates a new image from
raw pixel data, discarding all metadata from the source.

### Allowed File Types

Only the following file types are accepted:
- Images: `.jpg`, `.jpeg`, `.png`
- Documents: `.pdf`

File type detection uses extension matching. The file is then validated by
attempting to open it with Pillow (images) or PyMuPDF (PDFs).

---

## Error Logging

### Log Location

Error logs are written to a platform-appropriate directory:

| Platform | Path |
|----------|------|
| macOS | `~/Library/Logs/PassportFiligrane/error_log.txt` |
| Windows | `%APPDATA%/PassportFiligrane/Logs/error_log.txt` |
| Linux | `~/.local/state/PassportFiligrane/error_log.txt` (or `$XDG_STATE_HOME`) |

### Privacy Protections

- The log directory is created with permissions `0o700` (owner-only access)
- The log file is set to `0o600` after each write (owner read/write only)
- File paths in error messages are sanitized: the user's home directory is
  replaced with `~USER` before writing to the log
- Stack traces are logged for debugging but do not contain user document content

### What Is NOT Logged

- File contents or document text
- Watermark text configured by the user
- Slider positions or UI state

---

## Thread Safety

The preview generation runs in a debounced background thread (`threading.Timer`)
to avoid blocking the UI. A `threading.Lock` (`_preview_lock`) protects shared
state during preview generation to prevent race conditions when:

- The user loads a new file while a preview is still rendering
- Rapid slider adjustments trigger overlapping preview updates

---

## Watermark Security Model

### Vector Mode (Default)

- The watermark is added as a PDF text overlay using `page.insert_text()`
- The watermark text is **selectable** and **extractable** (`page.get_text()`)
- The watermark **can be removed** with any PDF editor (Adobe Acrobat, Preview, etc.)
- Suitable for **internal use** where removability is acceptable

**A visible warning is displayed in the UI when vector mode is active on PDFs.**

### Secure Raster Mode

- Each page is rendered to a bitmap at the selected DPI (300/450/600)
- The watermark is composited into the pixel data
- The result is a flat image inserted into a new PDF -- no selectable text remains
- The watermark **cannot be removed** without visibly damaging the document
- Suitable for **public-facing documents** and identity document protection

### Recommendation for Sensitive Documents

For identity documents (passports, ID cards, etc.), **always use Secure Raster
Mode**. Vector mode should only be used for internal drafts where document
quality and selectability are priorities.

