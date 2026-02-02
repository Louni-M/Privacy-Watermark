import pytest
import os
import fitz
from pdf_processing import load_pdf, pdf_page_to_image, apply_watermark_to_pdf
from PIL import Image
import io

@pytest.fixture
def sample_pdf(tmp_path):
    """Crée un PDF simple pour les tests."""
    pdf_path = tmp_path / "test.pdf"
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((50, 50), "Test Page 1")
    doc.new_page()
    doc.save(str(pdf_path))
    doc.close()
    return str(pdf_path)

@pytest.fixture
def protected_pdf(tmp_path):
    """Crée un PDF protégé par mot de passe."""
    pdf_path = tmp_path / "protected.pdf"
    doc = fitz.open()
    doc.new_page()
    doc.save(str(pdf_path), encryption=fitz.PDF_ENCRYPT_AES_256, owner_pw="owner", user_pw="user")
    doc.close()
    return str(pdf_path)

@pytest.fixture
def corrupt_pdf(tmp_path):
    """Crée un fichier PDF corrompu."""
    pdf_path = tmp_path / "corrupt.pdf"
    with open(pdf_path, "w") as f:
        f.write("Definitely not a PDF")
    return str(pdf_path)

def test_load_pdf_valid(sample_pdf):
    doc, num_pages = load_pdf(sample_pdf)
    assert num_pages == 2
    assert isinstance(doc, fitz.Document)
    doc.close()

def test_load_pdf_protected(protected_pdf):
    with pytest.raises(Exception) as excinfo:
        load_pdf(protected_pdf)
    assert "protégé" in str(excinfo.value).lower()

def test_load_pdf_corrupt(corrupt_pdf):
    with pytest.raises(Exception) as excinfo:
        load_pdf(corrupt_pdf)
    assert "impossible" in str(excinfo.value).lower() or "valide" in str(excinfo.value).lower()

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
