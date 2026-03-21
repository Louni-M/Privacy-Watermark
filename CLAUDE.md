Last updated at commit: 65fd2af
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Passport Filigrane** is a macOS desktop application for watermarking documents (passports, IDs, etc.) with customizable text watermarks. It strips EXIF metadata from exports and offers two watermark modes:
- **Vector Mode**: Watermark added as PDF text overlay (selectable/removable)
- **Secure Raster Mode**: Pages rendered at 300/450/600 DPI with watermark composited into pixels (indelible)

## Tech Stack

- **Flet** (0.21.2): UI framework
- **PyMuPDF** (>=1.25.0): PDF manipulation and vector watermarking
- **Pillow** (>=10.3.0): Image processing and raster watermarking
- **PyInstaller** (>=6.0.0): macOS app packaging

## Architecture

```
main.py              # Entry point: flet.app(target=main)
app.py               # PassportFiligraneApp: UI layout, state, event handlers
pdf_processing.py    # PDF load/save, vector watermark, secure raster watermark
watermark.py         # WatermarkParams dataclass, PIL watermark functions
utils.py             # File validation, metadata stripping, platform logging
constants.py         # Colors, DPI options, JPEG quality, input limits
```

**Two watermark implementations:**
1. `apply_vector_watermark_to_pdf()` in `pdf_processing.py` — uses PyMuPDF `page.insert_text()` with rotation matrix
2. `apply_watermark_to_pil_image()` in `watermark.py` — PIL-based diagonal tile overlay

Preview generation runs in a debounced background thread (`threading.Timer`, 0.5s) with `_preview_lock` protecting shared state. `_pixmap_to_image()` in `pdf_processing.py` handles PyMuPDF→PIL conversion.

## Development Commands

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
source venv/bin/activate && python3 main.py

# Run tests
source venv/bin/activate && python3 -m pytest
python3 -m pytest tests/test_pdf_processing.py  # single test file
python3 -m pytest tests/ -k "watermark"         # run tests matching pattern

# Build macOS app
python3 -m PyInstaller "Passport Filigrane.spec" --clean
# Output: dist/Passport Filigrane.app
```

## Input Validation Limits

| Limit | Value | Location |
|-------|-------|----------|
| Max file size | 100 MB | `constants.py` - `MAX_FILE_SIZE_BYTES` |
| Max PDF pages | 50 | `constants.py` - `MAX_PDF_PAGES` |
| Max image dimension | 20,000 px | `constants.py` - `MAX_IMAGE_DIMENSION` |
| Max watermark text | 200 chars | `watermark.py` - `apply_watermark_to_pil_image()` |

## Watermark Color/Orientation Maps

- `WATERMARK_COLOR_MAP` (PyMuPDF float RGB 0-1): White, Black, Gray
- `PIL_COLOR_MAP` (Pillow int RGB 0-255): White, Black, Gray
- `WATERMARK_ORIENTATION_MAP`: Ascending (↗) = 45°, Descending (↘) = -45°

## Build Output

The PyInstaller spec targets `onedir` mode. The BUNDLE step wraps it into `Passport Filigrane.app` with the icon from `assets/app_icon.icns`.
