import pytest
import os
import fitz
from pdf_processing import load_pdf, pdf_page_to_image, apply_watermark_to_pdf, generate_pdf_preview
from PIL import Image
import io



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
    # PyMuPDF default DPI rendering might result in different sizes, 
    # but for a standard A4 it's usually around 595x841 at 72dpi.
    assert img.width > 0 and img.height > 0
    doc.close()

def test_apply_watermark_to_pdf(sample_pdf):
    doc, num_pages = load_pdf(sample_pdf)
    watermark_params = {
        "text": "COPIE",
        "opacity": 50,
        "font_size": 36,
        "spacing": 150
    }
    # Execute
    apply_watermark_to_pdf(doc, watermark_params)
    
    # Verify
    assert doc.page_count == num_pages
    img_after = pdf_page_to_image(doc, 0)
    
    # Reload original to compare
    doc_orig = fitz.open(sample_pdf)
    img_before = pdf_page_to_image(doc_orig, 0)
    doc_orig.close()
    
    # They should be different if watermark was applied
    assert img_after.tobytes() != img_before.tobytes()
    doc.close()

def test_generate_pdf_preview(sample_pdf):
    doc, _ = load_pdf(sample_pdf)
    preview_bytes = generate_pdf_preview(
        doc=doc,
        text="PREVIEW",
        opacity=50,
        font_size=50,
        spacing=100,
        color="Black"
    )
    
    assert isinstance(preview_bytes, bytes)
    assert len(preview_bytes) > 0
    
    # Verify it is a valid image
    img = Image.open(io.BytesIO(preview_bytes))
    assert img.format == "PNG"
    assert img.width > 0
    assert img.height > 0
    doc.close()
