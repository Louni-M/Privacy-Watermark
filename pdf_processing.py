"""PDF-specific watermarking and I/O operations using PyMuPDF."""

from __future__ import annotations

from PIL import Image
import io
import os
import fitz

from constants import (
    WATERMARK_COLOR_MAP,
    WATERMARK_ORIENTATION_MAP,
    JPEG_EXPORT_QUALITY,
    JPEG_SECURE_QUALITY,
)
from watermark import WatermarkParams, get_font, apply_watermark_to_pil_image  # noqa: F401 (re-exported)


class PdfLoadError(RuntimeError):
    """Base exception for PDF loading failures."""
    pass


class ProtectedPdfError(PdfLoadError):
    """Raised when a PDF is password-protected and cannot be opened."""
    pass


class InvalidPdfError(PdfLoadError):
    """Raised when a PDF is corrupted or has no readable pages."""
    pass


def load_pdf(file_path: str) -> tuple[fitz.Document, int]:
    """
    Load a PDF file and return (document, page_count).
    Raises PdfLoadError (or subclass) if the PDF cannot be opened.
    """
    try:
        doc = fitz.open(file_path)
        if doc.is_encrypted:
            raise ProtectedPdfError("This PDF is password-protected and cannot be opened.")
        if doc.page_count == 0:
            raise InvalidPdfError("Unable to read this PDF file (no pages).")
        return doc, doc.page_count
    except fitz.FileDataError:
        raise InvalidPdfError("Unable to read this PDF file.")
    except PdfLoadError:
        raise
    except Exception as e:
        raise PdfLoadError(f"Error loading PDF: {e}") from e


def pdf_page_to_image(doc: fitz.Document, page_num: int) -> Image.Image:
    """Convert a PDF page to a PIL Image (RGBA)."""
    page = doc.load_page(page_num)
    pix = page.get_pixmap(alpha=True)
    return Image.frombytes("RGBA", [pix.width, pix.height], pix.samples)


def apply_vector_watermark_to_pdf(doc: fitz.Document, params: WatermarkParams) -> None:
    """
    Apply a native vector watermark on all pages of the PDF document.

    Uses page.insert_text() from PyMuPDF to add vector watermarks that preserve
    the quality of the original PDF. Text remains sharp at any zoom level and
    the original content stays selectable.

    Args:
        doc: PDF document to watermark (modified in place)
        params: WatermarkParams with text, opacity, font_size, spacing, color, orientation
    """
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        apply_vector_watermark_to_page(page, params)


def apply_vector_watermark_to_page(page: fitz.Page, params: WatermarkParams) -> None:
    """
    Apply a vector watermark on a single PDF page.

    Args:
        page: PyMuPDF page (modified in place)
        params: WatermarkParams with text, opacity, font_size, spacing, color, orientation
    """
    rgb = WATERMARK_COLOR_MAP.get(params.color, (1.0, 1.0, 1.0))
    fill_opacity = params.opacity / 100.0
    rotation_angle = WATERMARK_ORIENTATION_MAP.get(params.orientation, 45)

    page_width = page.rect.width
    page_height = page.rect.height

    y = -params.spacing
    row = 0

    while y < page_height + params.spacing:
        x = -params.spacing

        if row % 2 == 0:
            x += params.spacing // 2

        while x < page_width + params.spacing:
            point = fitz.Point(x, y)
            page.insert_text(
                point=point,
                text=params.text,
                fontsize=params.font_size,
                fontname="helv",
                color=rgb,
                morph=(point, fitz.Matrix(rotation_angle)),
                fill_opacity=fill_opacity,
                overlay=True,
            )
            x += params.spacing

        y += params.spacing
        row += 1


def save_watermarked_pdf(doc: fitz.Document, output_path: str) -> None:
    """Save the modified PDF document."""
    doc.save(output_path)


def save_image_as_pdf(image_bytes: bytes, output_path: str) -> None:
    """
    Convert a watermarked image (bytes) to a single-page PDF.
    The PDF page size will match the image dimensions in points (72 DPI).
    """
    img = Image.open(io.BytesIO(image_bytes))
    width, height = img.size

    pdf_doc = fitz.open()
    page = pdf_doc.new_page(width=width, height=height)
    page.insert_image(page.rect, stream=image_bytes)

    pdf_doc.save(output_path)
    pdf_doc.close()


def save_pdf_as_images(
    doc: fitz.Document, output_dir: str, base_name: str, img_format: str = "JPEG"
) -> None:
    """
    Save each page of the PDF as an individual image (JPG or PNG).
    Output images are created from raw pixel data (no EXIF metadata).
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for i in range(len(doc)):
        page = doc.load_page(i)
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        ext = "png" if img_format.upper() == "PNG" else "jpg"
        pil_fmt = "PNG" if img_format.upper() == "PNG" else "JPEG"
        output_path = os.path.join(output_dir, f"{base_name}_page_{i+1:03d}.{ext}")

        if pil_fmt == "JPEG":
            img.save(output_path, pil_fmt, quality=JPEG_EXPORT_QUALITY)
        else:
            img.save(output_path, pil_fmt)


def generate_pdf_preview(doc: fitz.Document, params: WatermarkParams) -> bytes:
    """
    Generate a preview of the first page with the watermark applied.
    Does not modify the original document. Returns PNG bytes.

    Args:
        doc: PyMuPDF document
        params: WatermarkParams with text, opacity, font_size, spacing, color, orientation
    """
    img = pdf_page_to_image(doc, 0)
    watermarked = apply_watermark_to_pil_image(img, params)
    buf = io.BytesIO()
    watermarked.save(buf, format="PNG")
    return buf.getvalue()


def apply_secure_raster_watermark_to_pdf(
    doc: fitz.Document, params: WatermarkParams, dpi: int = 300
) -> fitz.Document:
    """
    Apply a watermark on a PDF by rendering each page as an image (rasterization).
    This makes the watermark inseparable from the original content.

    Args:
        doc: PyMuPDF document
        params: WatermarkParams with text, opacity, font_size, spacing, color, orientation
        dpi: Resolution in DPI (300, 450, or 600)

    Returns:
        New fitz.Document with rasterized watermarked pages
    """
    out_doc = fitz.open()

    zoom = dpi / 72
    mat = fitz.Matrix(zoom, zoom)

    # Scale font size and spacing proportionally to DPI for consistent visual appearance
    scale_factor = dpi / 72
    adjusted_params = WatermarkParams(
        text=params.text,
        opacity=params.opacity,
        font_size=int(params.font_size * scale_factor),
        spacing=int(params.spacing * scale_factor),
        color=params.color,
        orientation=params.orientation,
    )

    for page in doc:
        pix = page.get_pixmap(matrix=mat, alpha=False)
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        img_rgba = img.convert("RGBA")

        watermarked_img = apply_watermark_to_pil_image(img_rgba, adjusted_params)

        final_img = watermarked_img.convert("RGB")
        new_page = out_doc.new_page(width=page.rect.width, height=page.rect.height)

        img_buffer = io.BytesIO()
        final_img.save(img_buffer, format="JPEG", quality=JPEG_SECURE_QUALITY)
        new_page.insert_image(new_page.rect, stream=img_buffer.getvalue())

    return out_doc
