import sys
import os
import pytest
import fitz
import flet as ft
from unittest.mock import MagicMock

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from app import PassportFiligraneApp


def find_all_controls(controls, control_type, results=None):
    """Recursively find all controls of a given type in a Flet control tree."""
    if results is None:
        results = []
    for c in controls:
        if isinstance(c, control_type):
            results.append(c)
        if hasattr(c, "controls") and c.controls:
            find_all_controls(c.controls, control_type, results)
        if hasattr(c, "content") and c.content:
            if isinstance(c.content, ft.Column) or isinstance(c.content, ft.Row):
                find_all_controls(c.content.controls, control_type, results)
    return results


@pytest.fixture
def app():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    mock_page.controls = []
    return PassportFiligraneApp(mock_page)


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
