from unittest.mock import MagicMock, patch

import flet as ft

from sensitive_document_intake import AcceptedPdf, IntakeRejected


def _file_result(path: str):
    event = MagicMock(spec=ft.FilePickerResultEvent)
    event.files = [MagicMock(path=path)]
    return event


def test_rejected_intake_closes_previous_pdf_without_finalizing(app):
    previous_doc = MagicMock()
    app.pdf_doc = previous_doc
    app.current_file_type = "pdf"
    app.num_pages = 3

    with patch("app.intake_sensitive_document", return_value=IntakeRejected("Unable to read this PDF file.")), \
         patch.object(app, "update_preview") as update_preview:
        app.on_file_result(_file_result("broken.pdf"))

    previous_doc.close.assert_called_once()
    update_preview.assert_not_called()
    assert app.current_file_type is None
    assert app.pdf_doc is None
    assert app.num_pages == 0
    assert app.export_format_dropdown.visible is False
    assert app.secure_mode_switch.visible is False
    assert app.watermark_text.disabled is True


def test_accepted_pdf_replaces_previous_pdf(app):
    previous_doc = MagicMock()
    next_doc = MagicMock()
    app.pdf_doc = previous_doc
    result = AcceptedPdf("next.pdf", "next.pdf", next_doc, 4)

    with patch("app.intake_sensitive_document", return_value=result), \
         patch.object(app, "update_preview"):
        app.on_file_result(_file_result("next.pdf"))

    previous_doc.close.assert_called_once()
    assert app.pdf_doc is next_doc
    assert app.current_file_type == "pdf"
    assert app.num_pages == 4
    assert app.file_info_text.value == "PDF loaded: 4 page(s)"
