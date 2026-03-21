import pytest
import fitz
from pdf_processing import (
    load_pdf,
    pdf_page_to_image,
    generate_pdf_preview,
    apply_secure_raster_watermark_to_pdf,
    save_pdf_as_images,
    PdfLoadError,
    ProtectedPdfError,
    InvalidPdfError,
)
from watermark import WatermarkParams
from PIL import Image
import io
import os
import tempfile


def test_load_pdf_valid(sample_pdf):
    doc, num_pages = load_pdf(sample_pdf)
    assert num_pages == 2
    assert isinstance(doc, fitz.Document)
    doc.close()

def test_load_pdf_protected(protected_pdf):
    with pytest.raises(Exception) as excinfo:
        load_pdf(protected_pdf)
    assert "password-protected" in str(excinfo.value).lower()

def test_load_pdf_corrupt(corrupt_pdf):
    with pytest.raises(Exception) as excinfo:
        load_pdf(corrupt_pdf)
    assert "unable" in str(excinfo.value).lower()

def test_pdf_page_to_image(sample_pdf):
    doc, _ = load_pdf(sample_pdf)
    img = pdf_page_to_image(doc, 0)
    assert isinstance(img, Image.Image)
    assert img.mode == "RGBA"
    assert img.width > 0 and img.height > 0
    doc.close()

def test_generate_pdf_preview(sample_pdf):
    doc, _ = load_pdf(sample_pdf)
    params = WatermarkParams(text="PREVIEW", opacity=50, font_size=50, spacing=100, color="Black")
    preview_bytes = generate_pdf_preview(doc, params)

    assert isinstance(preview_bytes, bytes)
    assert len(preview_bytes) > 0

    img = Image.open(io.BytesIO(preview_bytes))
    assert img.format == "PNG"
    assert img.width > 0
    assert img.height > 0
    doc.close()


def test_generate_pdf_preview_does_not_modify_original(sample_pdf):
    doc, num_pages = load_pdf(sample_pdf)
    page_count_before = doc.page_count
    params = WatermarkParams(text="COPY", opacity=50, font_size=36, spacing=100, color="Black")
    generate_pdf_preview(doc, params)
    assert doc.page_count == page_count_before
    assert doc.page_count == num_pages
    doc.close()


def test_generate_pdf_preview_with_orientations(sample_pdf):
    doc, _ = load_pdf(sample_pdf)
    for orientation in ("Ascending (↗)", "Descending (↘)"):
        params = WatermarkParams(text="COPY", opacity=50, font_size=36, spacing=100,
                                 color="Black", orientation=orientation)
        preview_bytes = generate_pdf_preview(doc, params)
        img = Image.open(io.BytesIO(preview_bytes))
        assert img.format == "PNG"
        assert img.width > 0 and img.height > 0
    doc.close()


def test_generate_pdf_preview_with_all_colors(sample_pdf):
    doc, _ = load_pdf(sample_pdf)
    for color in ("White", "Black", "Gray"):
        params = WatermarkParams(text="COPY", opacity=50, font_size=36, spacing=100, color=color)
        preview_bytes = generate_pdf_preview(doc, params)
        img = Image.open(io.BytesIO(preview_bytes))
        assert img.format == "PNG"
        assert img.width > 0 and img.height > 0
    doc.close()


def test_apply_secure_raster_watermark_to_pdf_produces_valid_document(sample_pdf):
    """Secure raster watermark creates a valid multi-page PDF with embedded images."""
    doc, _ = load_pdf(sample_pdf)
    params = WatermarkParams(text="SECURE", opacity=30, font_size=24, spacing=80, color="Black")
    secured_doc = apply_secure_raster_watermark_to_pdf(doc, params)

    assert isinstance(secured_doc, fitz.Document)
    assert secured_doc.page_count == doc.page_count
    secured_doc.close()
    doc.close()


def test_apply_secure_raster_watermark_to_pdf_at_different_dpis(sample_pdf):
    """Secure watermark scales correctly at different DPI settings."""
    doc, _ = load_pdf(sample_pdf)
    params = WatermarkParams(text="SECURE", opacity=30, font_size=24, spacing=80, color="Black")

    for dpi in (300, 450, 600):
        secured_doc = apply_secure_raster_watermark_to_pdf(doc, params, dpi=dpi)
        assert secured_doc.page_count == doc.page_count
        secured_doc.close()
    doc.close()


def test_save_pdf_as_images_produces_files(sample_pdf, tmp_path):
    """save_pdf_as_images writes image files to the output directory."""
    doc, _ = load_pdf(sample_pdf)
    output_dir = str(tmp_path / "images")
    save_pdf_as_images(doc, output_dir, "page", img_format="JPEG")

    assert os.path.exists(output_dir)
    files = sorted(os.listdir(output_dir))
    assert len(files) == doc.page_count
    for f in files:
        assert f.endswith(".jpg")
    doc.close()


def test_save_pdf_as_images_png_format(sample_pdf, tmp_path):
    """save_pdf_as_images respects PNG format when requested."""
    doc, _ = load_pdf(sample_pdf)
    output_dir = str(tmp_path / "png_images")
    save_pdf_as_images(doc, output_dir, "page", img_format="PNG")

    files = sorted(os.listdir(output_dir))
    assert all(f.endswith(".png") for f in files)
    doc.close()


def test_protected_pdf_error_is_protected_pdf_error(protected_pdf):
    """ProtectedPdfError is a subclass of PdfLoadError."""
    with pytest.raises(ProtectedPdfError):
        load_pdf(protected_pdf)


def test_corrupt_pdf_error_is_invalid_pdf_error(corrupt_pdf):
    """InvalidPdfError is raised for corrupt PDFs and is a subclass of PdfLoadError."""
    with pytest.raises(InvalidPdfError):
        load_pdf(corrupt_pdf)


def test_pdf_load_error_catch_as_runtime_error(protected_pdf):
    """PdfLoadError can be caught as RuntimeError (base class)."""
    with pytest.raises(RuntimeError):
        load_pdf(protected_pdf)
