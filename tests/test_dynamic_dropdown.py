import pytest
import flet as ft
from unittest.mock import MagicMock, patch, mock_open
from app import PassportFiligraneApp

def test_dropdown_options_for_image(app):
    # Simulate image upload
    mock_event = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event.files = [MagicMock(path="test.jpg")]

    mock_img = MagicMock()
    mock_img.width = 100
    mock_img.height = 100
    mock_img.verify = MagicMock()

    with patch("app.detect_file_type", return_value="image"), \
         patch("builtins.open", mock_open(read_data=b"fake-image-data")), \
         patch("PIL.Image.open", return_value=mock_img), \
         patch("app.validate_file_size"):

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

    with patch("app.detect_file_type", return_value="pdf"), \
         patch("pdf_processing.load_pdf", return_value=(MagicMock(), 1)), \
         patch("app.validate_file_size"):
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
    mock_img = MagicMock()
    mock_img.width = 100
    mock_img.height = 100
    mock_img.verify = MagicMock()

    with patch("app.detect_file_type", return_value="image"), \
         patch("builtins.open", mock_open(read_data=b"data")), \
         patch("PIL.Image.open", return_value=mock_img), \
         patch("app.validate_file_size"):
        app.on_file_result(mock_event_img)

    assert app.export_format_dropdown.visible is True

    mock_event_bad = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event_bad.files = [MagicMock(path="test.txt")]
    with patch("app.detect_file_type", return_value="unknown"), \
         patch("app.validate_file_size"):
        app.on_file_result(mock_event_bad)

    assert app.export_format_dropdown.visible is False
