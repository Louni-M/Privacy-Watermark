
import pytest
import fitz
import io
import os
from pdf_processing import load_pdf, apply_vector_watermark_to_pdf
from PIL import Image

def create_encrypted_pdf(path):
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((100, 100), "Secret Content")
    doc.save(path, encryption=fitz.PDF_ENCRYPT_AES_256, user_pw="secret", owner_pw="admin")
    doc.close()

def create_large_pdf(path, pages=20):
    doc = fitz.open()
    for i in range(pages):
        page = doc.new_page()
        page.insert_text((100, 100), f"Page {i+1}")
    doc.save(path)
    doc.close()

def create_image_pdf(path):
    # Create an image in memory (no temp file on disk)
    img = Image.new('RGB', (100, 100), color='red')
    img_buffer = io.BytesIO()
    img.save(img_buffer, format="JPEG")

    doc = fitz.open()
    page = doc.new_page()
    page.insert_image(page.rect, stream=img_buffer.getvalue())
    doc.save(path)
    doc.close()

@pytest.fixture
def encrypted_pdf_path(tmp_path):
    path = tmp_path / "encrypted.pdf"
    create_encrypted_pdf(str(path))
    return str(path)

@pytest.fixture
def large_pdf_path(tmp_path):
    path = tmp_path / "large.pdf"
    create_large_pdf(str(path))
    return str(path)

@pytest.fixture
def image_pdf_path(tmp_path):
    path = tmp_path / "image.pdf"
    create_image_pdf(str(path))
    return str(path)

def test_encrypted_pdf_handling(encrypted_pdf_path):
    """Test that encrypted PDFs raise a user-friendly exception."""
    with pytest.raises(Exception) as excinfo:
        load_pdf(encrypted_pdf_path)
    assert "password-protected" in str(excinfo.value)

def test_large_pdf_handling(large_pdf_path):
    """Test watermarking a larger PDF."""
    doc, count = load_pdf(large_pdf_path)
    assert count == 20
    
    # Should not crash
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="WATERMARK",
        opacity=30,
        font_size=36,
        spacing=150,
        color="Black"
    )
    
    # Check watermark on first and last page
    page0 = doc.load_page(0)
    # Checking text presence in page text might not work for overlay? 
    # insert_text adds properly to the page content.
    # PyMuPDF 'get_text' usually extracts text content.
    assert "WATERMARK" in page0.get_text()
    
    page_last = doc.load_page(19)
    assert "WATERMARK" in page_last.get_text()

def test_image_pdf_handling(image_pdf_path):
    """Test watermarking a PDF that contains only images."""
    doc, count = load_pdf(image_pdf_path)
    
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="WATERMARK",
        opacity=30,
        font_size=36,
        spacing=150,
        color="Black"
    )
    
    page = doc.load_page(0)
    # The watermark text should be added on top of the image
    assert "WATERMARK" in page.get_text()
