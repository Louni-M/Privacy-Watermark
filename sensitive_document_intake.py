"""Sensitive document intake for selected image and PDF files."""

from __future__ import annotations

import io
import os
from dataclasses import dataclass

from PIL import Image

from constants import MAX_PDF_PAGES
from pdf_processing import PdfLoadError, load_pdf
from utils import detect_file_type, validate_file_size, validate_image_dimensions


@dataclass(frozen=True)
class AcceptedImage:
    file_path: str
    filename: str
    image_bytes: bytes


@dataclass(frozen=True)
class AcceptedPdf:
    file_path: str
    filename: str
    document: object
    page_count: int


@dataclass(frozen=True)
class IntakeRejected:
    message: str


SensitiveDocumentIntakeResult = AcceptedImage | AcceptedPdf | IntakeRejected


def intake_sensitive_document(file_path: str) -> SensitiveDocumentIntakeResult:
    """Validate and load a selected sensitive document."""
    try:
        validate_file_size(file_path)
    except ValueError as exc:
        return IntakeRejected(str(exc))

    file_type = detect_file_type(file_path)
    if file_type == "image":
        return _intake_image(file_path)
    if file_type == "pdf":
        return _intake_pdf(file_path)

    return IntakeRejected("Unsupported file format.")


def _intake_image(file_path: str) -> SensitiveDocumentIntakeResult:
    try:
        with open(file_path, "rb") as f:
            content = f.read()
        img = Image.open(io.BytesIO(content))
        img.verify()
        img = Image.open(io.BytesIO(content))
        validate_image_dimensions(img)
    except ValueError as exc:
        return IntakeRejected(str(exc))
    except Exception:
        return IntakeRejected("Unable to read this image file.")

    return AcceptedImage(
        file_path=file_path,
        filename=os.path.basename(file_path),
        image_bytes=content,
    )


def _intake_pdf(file_path: str) -> SensitiveDocumentIntakeResult:
    try:
        document, page_count = load_pdf(file_path)
    except PdfLoadError as exc:
        return IntakeRejected(str(exc))

    if page_count > MAX_PDF_PAGES:
        document.close()
        return IntakeRejected(
            f"PDF too large ({page_count} pages). "
            f"Maximum allowed is {MAX_PDF_PAGES} pages."
        )

    return AcceptedPdf(
        file_path=file_path,
        filename=os.path.basename(file_path),
        document=document,
        page_count=page_count,
    )
