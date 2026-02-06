import pytest
import flet as ft
from unittest.mock import MagicMock, patch, mock_open
from main import PassportFiligraneApp
import io
from PIL import Image

@pytest.fixture
def app():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    mock_page.controls = []
    return PassportFiligraneApp(mock_page)

def test_image_to_pdf_save_dialog_params(app):
    # Setup
    app.current_file_type = "image"
    app.export_format_dropdown.value = "PDF"
    
    # Mock save_file_picker
    app.save_file_picker.save_file = MagicMock()
    
    # Execute
    app.on_save_button_click(None)
    
    # Verify PDF params
    call_args = app.save_file_picker.save_file.call_args[1]
    assert call_args["file_name"] == "export_filigree.pdf"
    assert "pdf" in call_args["allowed_extensions"]

def test_save_image_as_pdf_integration(app):
    # This tests the processing chain in main.py
    app.current_file_type = "image"
    app.export_format_dropdown.value = "PDF"
    app.watermarked_image_bytes = b"fake-img-data"
    
    mock_event = MagicMock()
    mock_event.path = "output.pdf"
    
    # We need to mock the new function save_image_as_pdf
    with patch("main.save_image_as_pdf") as mock_save_pdf:
        app.on_save_result(mock_event)
        mock_save_pdf.assert_called_once_with(b"fake-img-data", "output.pdf")

def test_pdf_processing_save_image_as_pdf():
    # Test the actual PDF generation logic in pdf_processing.py
    from pdf_processing import save_image_as_pdf
    
    # Create a dummy image
    img = Image.new("RGB", (100, 200), color="blue")
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    img_bytes = buf.getvalue()
    
    out_buf = io.BytesIO()
    # Mocking open since save_image_as_pdf might write to a file path
    with patch("pdf_processing.fitz.open") as mock_fitz_open:
        mock_doc = MagicMock()
        mock_fitz_open.return_value = mock_doc
        
        save_image_as_pdf(img_bytes, "dummy.pdf")
        
        # Verify document creation
        assert mock_fitz_open.called
        # Verify page insertion (insert_pdf or new_page + insert_image)
        assert mock_doc.new_page.called
        assert mock_doc.save.called
