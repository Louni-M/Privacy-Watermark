import pytest
import flet as ft
from unittest.mock import MagicMock, patch, mock_open
from main import PassportFiligraneApp

@pytest.fixture
def app():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    mock_page.controls = []
    # Avoid instantiation errors by mocking things if needed, 
    # but PassportFiligraneApp seems to just setup UI.
    return PassportFiligraneApp(mock_page)

def test_dropdown_options_for_image(app):
    # Simulate image upload
    mock_event = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event.files = [MagicMock(path="test.jpg")]
    
    # Mocking necessary parts for on_file_result to succeed
    with patch("main.detect_file_type", return_value="image"), \
         patch("main.open", mock_open(read_data=b"fake-image-data")), \
         patch("main.Image.open") as mock_img_open, \
         patch("main.validate_file_size"):
        
        mock_img = MagicMock()
        mock_img.width = 100
        mock_img.height = 100
        mock_img_open.return_value = mock_img
        
        app.on_file_result(mock_event)
    
    # Verify dropdown is visible and has correct options
    assert app.export_format_dropdown.visible == True
    options = [opt.key for opt in app.export_format_dropdown.options]
    assert "JPG" in options
    assert "PNG" in options
    assert "PDF" in options
    assert app.export_format_dropdown.value == "JPG"

def test_dropdown_options_for_pdf(app):
    # Simulate PDF upload
    mock_event = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event.files = [MagicMock(path="test.pdf")]
    
    with patch("main.detect_file_type", return_value="pdf"), \
         patch("main.load_pdf", return_value=(MagicMock(), 1)), \
         patch("main.validate_file_size"):
        app.on_file_result(mock_event)
            
    # Verify
    assert app.export_format_dropdown.visible == True
    options = {opt.key: opt.text for opt in app.export_format_dropdown.options}
    assert "PDF" in options
    assert "Images" in options or "Images (JPG)" in options # Current is "Images"
    assert "Images (PNG)" in options
    assert app.export_format_dropdown.value == "PDF"

def test_dropdown_visibility_reset(app):
    # 1. Upload image
    mock_event_img = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event_img.files = [MagicMock(path="test.jpg")]
    with patch("main.detect_file_type", return_value="image"), \
         patch("main.open", mock_open(read_data=b"data")), \
         patch("main.Image.open") as mock_img_open, \
         patch("main.validate_file_size"):
        mock_img = MagicMock()
        mock_img.width = 100
        mock_img.height = 100
        mock_img_open.return_value = mock_img
        app.on_file_result(mock_event_img)
    
    assert app.export_format_dropdown.visible == True
    
    # 2. Upload unsupported file
    mock_event_bad = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event_bad.files = [MagicMock(path="test.txt")]
    with patch("main.detect_file_type", return_value="unknown"), \
         patch("main.validate_file_size"):
        app.on_file_result(mock_event_bad)
            
    # Verify hidden
    assert app.export_format_dropdown.visible == False
