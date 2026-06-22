import pytest
import flet as ft
from unittest.mock import MagicMock, patch
from app import PassportFiligraneApp
from sensitive_document_intake import AcceptedImage, AcceptedPdf, IntakeRejected

def test_dropdown_options_for_image(app):
    # Simulate image upload
    mock_event = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event.files = [MagicMock(path="test.jpg")]

    result = AcceptedImage("test.jpg", "test.jpg", b"fake-image-data")
    with patch("app.intake_sensitive_document", return_value=result), \
         patch.object(app, "update_preview"):
        app.on_file_result(mock_event)

    assert app.export_format_dropdown.visible is True
    options = [opt.key for opt in app.export_format_dropdown.options]
    assert "JPG" in options
    assert "PNG" in options
    assert "PDF" in options
    assert app.export_format_dropdown.value == "JPG"

def test_dropdown_options_for_pdf(app):
    mock_event = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event.files = [MagicMock(path="test.pdf")]

    result = AcceptedPdf("test.pdf", "test.pdf", MagicMock(), 1)
    with patch("app.intake_sensitive_document", return_value=result), \
         patch.object(app, "update_preview"):
        app.on_file_result(mock_event)

    assert app.export_format_dropdown.visible is True
    options = {opt.key: opt.text for opt in app.export_format_dropdown.options}
    assert "PDF" in options
    assert "Images (JPG)" in options
    assert "Images (PNG)" in options
    assert app.export_format_dropdown.value == "PDF"

def test_dropdown_visibility_reset(app):
    mock_event_img = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event_img.files = [MagicMock(path="test.jpg")]

    image_result = AcceptedImage("test.jpg", "test.jpg", b"data")
    with patch("app.intake_sensitive_document", return_value=image_result), \
         patch.object(app, "update_preview"):
        app.on_file_result(mock_event_img)

    assert app.export_format_dropdown.visible is True

    mock_event_bad = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event_bad.files = [MagicMock(path="test.txt")]
    with patch("app.intake_sensitive_document", return_value=IntakeRejected("Unsupported file format.")):
        app.on_file_result(mock_event_bad)

    assert app.export_format_dropdown.visible is False
