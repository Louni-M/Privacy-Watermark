import pytest
import flet as ft
from unittest.mock import MagicMock, patch, mock_open
from main import PassportFiligraneApp

@pytest.fixture
def app():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    mock_page.controls = []
    return PassportFiligraneApp(mock_page)

def test_integration_image_export_matrix(app):
    app.current_file_type = "image"
    app.save_file_picker.save_file = MagicMock()
    
    # Test JPG
    app.export_format_dropdown.value = "JPG"
    app.on_save_button_click(None)
    call_args = app.save_file_picker.save_file.call_args[1]
    assert call_args["file_name"].endswith(".jpg")
    
    # Test PNG
    app.export_format_dropdown.value = "PNG"
    app.on_save_button_click(None)
    call_args = app.save_file_picker.save_file.call_args[1]
    assert call_args["file_name"].endswith(".png")
    
    # Test PDF
    app.export_format_dropdown.value = "PDF"
    app.on_save_button_click(None)
    call_args = app.save_file_picker.save_file.call_args[1]
    assert call_args["file_name"].endswith(".pdf")

def test_integration_pdf_export_matrix(app):
    app.current_file_type = "pdf"
    app.save_file_picker.save_file = MagicMock()
    with patch.object(app.save_dir_picker, "get_directory_path") as mock_get_dir:
        # Test PDF
        app.export_format_dropdown.value = "PDF"
        app.on_save_button_click(None)
        call_args = app.save_file_picker.save_file.call_args[1]
        assert call_args["file_name"].endswith(".pdf")
        
        # Test Images (JPG)
        app.export_format_dropdown.value = "Images (JPG)"
        app.on_save_button_click(None)
        assert mock_get_dir.called
        
        # Test Images (PNG)
        mock_get_dir.reset_mock()
        app.export_format_dropdown.value = "Images (PNG)"
        app.on_save_button_click(None)
        assert mock_get_dir.called

def test_integration_backward_compatibility_on_file_result(app):
    # Verify existing flows (validation, type detection) aren't broken
    with patch("main.detect_file_type", return_value="image"), \
         patch("main.validate_file_size"), \
         patch("main.open", mock_open(read_data=b"fake-image-data")), \
         patch("main.Image.open") as mock_img_open:
        
        mock_img = MagicMock()
        mock_img.width = 100
        mock_img.height = 100
        mock_img_open.return_value = mock_img
        
        mock_event = MagicMock()
        mock_event.files = [MagicMock(path="test.jpg")]
        
        app.on_file_result(mock_event)
        
        assert app.current_file_type == "image"
        assert app.export_format_dropdown.visible == True
        assert app.export_format_dropdown.value == "JPG"
