import pytest
import fitz
import os

@pytest.fixture
def sample_pdf(tmp_path):
    """Create a simple PDF for tests."""
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
    """Create a password-protected PDF."""
    pdf_path = tmp_path / "protected.pdf"
    doc = fitz.open()
    doc.new_page()
    doc.save(str(pdf_path), encryption=fitz.PDF_ENCRYPT_AES_256, owner_pw="owner", user_pw="user")
    doc.close()
    return str(pdf_path)

@pytest.fixture
def corrupt_pdf(tmp_path):
    """Create a corrupt PDF file."""
    pdf_path = tmp_path / "corrupt.pdf"
    with open(pdf_path, "w") as f:
        f.write("Definitely not a PDF")
    return str(pdf_path)
