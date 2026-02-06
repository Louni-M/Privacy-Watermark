import pytest
import flet as ft
from unittest.mock import MagicMock, patch, mock_open
from main import PassportFiligraneApp, apply_watermark
import io
from PIL import Image

@pytest.fixture
def app():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    mock_page.controls = []
    return PassportFiligraneApp(mock_page)

def test_png_export_save_dialog_params(app):
    # Setup for image
    app.current_file_type = "image"
    app.export_format_dropdown.value = "PNG"
    
    # Mock save_file_picker
    app.save_file_picker.save_file = MagicMock()
    
    # Execute
    app.on_save_button_click(None)
    
    # Verify PNG params
    call_args = app.save_file_picker.save_file.call_args[1]
    assert call_args["file_name"] == "export_filigree.png"
    assert "png" in call_args["allowed_extensions"]

def test_pdf_images_png_trigger_dir_picker(app):
    # Setup for PDF
    app.current_file_type = "pdf"
    app.export_format_dropdown.value = "Images (PNG)"
    
    # Mock save_dir_picker.get_directory_path to avoid Flet page requirement
    with patch.object(app.save_dir_picker, "get_directory_path") as mock_get_dir:
        # Execute
        app.on_save_button_click(None)
        
        # Verify dir picker used
        assert mock_get_dir.called

def test_apply_watermark_supports_png_format():
    # Create a dummy image
    img = Image.new("RGB", (100, 100), color="red")
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    img_bytes = buf.getvalue()
    
    # Execute with PNG format
    png_bytes = apply_watermark(img_bytes, "TEST", 30, 20, 50, output_format="PNG")
    
    # Verify it is a PNG
    result_img = Image.open(io.BytesIO(png_bytes))
    assert result_img.format == "PNG"

def test_on_save_result_writes_png(app):
    app.current_file_type = "image"
    app.export_format_dropdown.value = "PNG"
    app.watermarked_image_bytes = b"png-data"
    
    mock_event = MagicMock()
    mock_event.path = "test.png"
    
    with patch("main.open", mock_open()) as mocked_file:
        app.on_save_result(mock_event)
        mocked_file.assert_called_with("test.png", "wb")
        mocked_file().write.assert_called_with(b"png-data")

def test_pdf_to_png_images_params(app):
    app.current_file_type = "pdf"
    app.export_format_dropdown.value = "Images (PNG)"
    app.pdf_doc = MagicMock()
    app.secure_mode_switch.value = False # Classic mode
    
    mock_event = MagicMock()
    mock_event.path = "/fake/dir"
    
    # Mock save_pdf_as_images
    with patch("main.save_pdf_as_images") as mock_save_pdf:
        app.on_dir_result(mock_event)
        args, kwargs = mock_save_pdf.call_args
        assert kwargs.get("img_format") == "PNG"
