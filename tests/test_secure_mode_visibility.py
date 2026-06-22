import pytest
from unittest.mock import MagicMock, patch
import flet as ft
from app import PassportFiligraneApp
from sensitive_document_intake import AcceptedPdf

def test_secure_mode_visible_for_pdf():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)

    # Mock PDF file selection
    mock_file = MagicMock()
    mock_file.path = "test_document.pdf"
    
    mock_event = MagicMock(spec=ft.FilePickerResultEvent)
    mock_event.files = [mock_file]

    result = AcceptedPdf("test_document.pdf", "test_document.pdf", MagicMock(), 5)
    with patch("app.intake_sensitive_document", return_value=result), \
         patch.object(app, "update_preview"):
        
        # Execute
        app.on_file_result(mock_event)

        # Verify
        assert app.current_file_type == "pdf"
        # This assertion is expected to FAIL before the fix
        assert app.secure_mode_switch.visible is True, "Secure Mode switch should be visible for PDFs"


def test_on_secure_mode_change_updates_visibility():
    """on_secure_mode_change reads secure_mode_switch.value and updates dpi_container visibility."""
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)

    # Start with secure mode OFF
    app.secure_mode_switch.value = False
    app.dpi_container.visible = False

    # Simulate switching secure mode ON (the switch controls the container)
    app.secure_mode_switch.value = True
    app.on_secure_mode_change(MagicMock())
    assert app.dpi_container.visible is True

    # Simulate switching secure mode OFF
    app.secure_mode_switch.value = False
    app.on_secure_mode_change(MagicMock())
    assert app.dpi_container.visible is False
