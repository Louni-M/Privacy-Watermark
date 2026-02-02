import pytest
import fitz
import os

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
