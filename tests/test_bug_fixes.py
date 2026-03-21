"""Tests for Phase 0 bug fixes."""
import pytest
import flet as ft
from unittest.mock import MagicMock
from app import PassportFiligraneApp


class TestJpegQualityConstants:
    """Phase 0b: JPEG quality values should be named constants."""

    def test_jpeg_export_quality_is_90(self):
        """Standard export (image watermark, pdf-to-images) uses quality=90."""
        import constants
        assert constants.JPEG_EXPORT_QUALITY == 90

    def test_jpeg_secure_quality_is_95(self):
        """Secure raster mode uses quality=95 (higher quality for security-critical output)."""
        import constants
        assert constants.JPEG_SECURE_QUALITY == 95


class TestUpdateSaveButtonText:
    """Phase 0a: _update_save_button_text() uses startswith('Images') not == 'Images'."""

    def test_images_jpg_shows_export_as_images(self, app):
        app.current_file_type = "pdf"
        app.export_format_dropdown.value = "Images (JPG)"
        app._update_save_button_text()
        assert app.save_button.text == "Export as images"

    def test_images_png_shows_export_as_images(self, app):
        app.current_file_type = "pdf"
        app.export_format_dropdown.value = "Images (PNG)"
        app._update_save_button_text()
        assert app.save_button.text == "Export as images"

    def test_pdf_export_shows_save_file(self, app):
        app.current_file_type = "pdf"
        app.export_format_dropdown.value = "PDF"
        app._update_save_button_text()
        assert app.save_button.text == "Save file"

    def test_image_file_type_shows_save_file(self, app):
        app.current_file_type = "image"
        app.export_format_dropdown.value = "JPG"
        app._update_save_button_text()
        assert app.save_button.text == "Save file"
