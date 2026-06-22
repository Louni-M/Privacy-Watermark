import io

import fitz
from PIL import Image

from constants import MAX_FILE_SIZE_BYTES, MAX_IMAGE_DIMENSION, MAX_PDF_PAGES
from sensitive_document_intake import (
    AcceptedImage,
    AcceptedPdf,
    IntakeRejected,
    intake_sensitive_document,
)


def test_intake_accepts_valid_image(tmp_path):
    image_path = tmp_path / "passport.png"
    image = Image.new("RGB", (24, 18), color="white")
    image.save(image_path)

    result = intake_sensitive_document(str(image_path))

    assert isinstance(result, AcceptedImage)
    assert result.file_path == str(image_path)
    assert result.filename == "passport.png"
    assert result.image_bytes == image_path.read_bytes()
    assert Image.open(io.BytesIO(result.image_bytes)).size == (24, 18)


def test_intake_accepts_valid_pdf(sample_pdf):
    result = intake_sensitive_document(sample_pdf)

    assert isinstance(result, AcceptedPdf)
    assert result.file_path == sample_pdf
    assert result.filename == "test.pdf"
    assert result.page_count == 2
    assert isinstance(result.document, fitz.Document)
    result.document.close()


def test_intake_rejects_unsupported_file(tmp_path):
    file_path = tmp_path / "notes.txt"
    file_path.write_text("not a supported sensitive document")

    result = intake_sensitive_document(str(file_path))

    assert isinstance(result, IntakeRejected)
    assert result.message == "Unsupported file format."


def test_intake_rejects_oversized_file(tmp_path):
    file_path = tmp_path / "huge.pdf"
    with open(file_path, "wb") as f:
        f.truncate(MAX_FILE_SIZE_BYTES + 1)

    result = intake_sensitive_document(str(file_path))

    assert isinstance(result, IntakeRejected)
    assert "File too large" in result.message


def test_intake_rejects_oversized_image_dimensions(tmp_path):
    image_path = tmp_path / "too-wide.png"
    image = Image.new("RGB", (MAX_IMAGE_DIMENSION + 1, 1), color="white")
    image.save(image_path)

    result = intake_sensitive_document(str(image_path))

    assert isinstance(result, IntakeRejected)
    assert "Image too large" in result.message


def test_intake_rejects_protected_pdf(protected_pdf):
    result = intake_sensitive_document(protected_pdf)

    assert isinstance(result, IntakeRejected)
    assert "password-protected" in result.message


def test_intake_rejects_corrupt_pdf(corrupt_pdf):
    result = intake_sensitive_document(corrupt_pdf)

    assert isinstance(result, IntakeRejected)
    assert "Unable to read this PDF file" in result.message


def test_intake_rejects_pdf_over_page_limit(tmp_path):
    pdf_path = tmp_path / "too-many-pages.pdf"
    doc = fitz.open()
    for _ in range(MAX_PDF_PAGES + 1):
        doc.new_page()
    doc.save(pdf_path)
    doc.close()

    result = intake_sensitive_document(str(pdf_path))

    assert isinstance(result, IntakeRejected)
    assert f"PDF too large ({MAX_PDF_PAGES + 1} pages)." in result.message
