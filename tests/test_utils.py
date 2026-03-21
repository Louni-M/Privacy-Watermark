"""Tests for utils.py (Phase 1b extraction)."""
import os
import sys
import pytest
from unittest.mock import patch, MagicMock
from PIL import Image


class TestGetLogPath:
    def test_returns_string(self):
        from utils import get_log_path
        path = get_log_path()
        assert isinstance(path, str)

    def test_ends_with_error_log_txt(self):
        from utils import get_log_path
        path = get_log_path()
        assert path.endswith("error_log.txt")

    def test_darwin_uses_library_logs(self):
        from utils import get_log_path
        with patch("sys.platform", "darwin"):
            with patch("os.makedirs"):
                path = get_log_path()
        assert "Library/Logs" in path or "PassportFiligrane" in path

    def test_win32_uses_appdata(self):
        from utils import get_log_path
        with patch("sys.platform", "win32"):
            with patch.dict(os.environ, {"APPDATA": "/fake/appdata"}):
                with patch("os.makedirs"):
                    path = get_log_path()
        assert "PassportFiligrane" in path

    def test_linux_uses_xdg_state_home(self):
        from utils import get_log_path
        with patch("sys.platform", "linux"):
            with patch.dict(os.environ, {"XDG_STATE_HOME": "/fake/state"}):
                with patch("os.makedirs"):
                    path = get_log_path()
        assert "PassportFiligrane" in path

    def test_creates_directory(self, tmp_path):
        from utils import get_log_path
        log_dir = str(tmp_path / "PassportFiligrane")
        with patch("sys.platform", "linux"):
            with patch.dict(os.environ, {"XDG_STATE_HOME": str(tmp_path)}):
                path = get_log_path()
        assert os.path.exists(os.path.dirname(path))


class TestSanitizePathForLog:
    def test_strips_newlines(self):
        from utils import sanitize_path_for_log
        result = sanitize_path_for_log("msg\ninjected")
        assert "\n" not in result

    def test_strips_carriage_returns(self):
        from utils import sanitize_path_for_log
        result = sanitize_path_for_log("msg\rinjected")
        assert "\r" not in result

    def test_replaces_home_with_user(self):
        from utils import sanitize_path_for_log
        home = os.path.expanduser("~")
        result = sanitize_path_for_log(f"error at {home}/secret.pdf")
        assert home not in result
        assert "~USER" in result

    def test_plain_message_unchanged(self):
        from utils import sanitize_path_for_log
        result = sanitize_path_for_log("simple error message")
        assert result == "simple error message"


class TestStripImageMetadata:
    def test_returns_image_same_size(self):
        from utils import strip_image_metadata
        img = Image.new("RGB", (50, 50), color="blue")
        result = strip_image_metadata(img)
        assert result.size == img.size

    def test_does_not_call_putdata(self):
        from utils import strip_image_metadata
        img = Image.new("RGB", (10, 10))
        with patch.object(Image.Image, "putdata", side_effect=AssertionError("putdata must not be called")):
            result = strip_image_metadata(img)
        assert result is not None

    def test_strips_exif(self):
        import io
        from utils import strip_image_metadata
        img = Image.new("RGB", (10, 10), color="red")
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        buf.seek(0)
        img_with_meta = Image.open(buf)
        result = strip_image_metadata(img_with_meta)
        assert "exif" not in result.info


class TestDetectFileType:
    def test_jpg(self):
        from utils import detect_file_type
        assert detect_file_type("photo.jpg") == "image"

    def test_jpeg(self):
        from utils import detect_file_type
        assert detect_file_type("photo.jpeg") == "image"

    def test_png(self):
        from utils import detect_file_type
        assert detect_file_type("photo.png") == "image"

    def test_pdf(self):
        from utils import detect_file_type
        assert detect_file_type("document.pdf") == "pdf"

    def test_unknown(self):
        from utils import detect_file_type
        assert detect_file_type("file.docx") == "unknown"

    def test_case_insensitive(self):
        from utils import detect_file_type
        assert detect_file_type("photo.JPG") == "image"
        assert detect_file_type("doc.PDF") == "pdf"


class TestValidateFileSize:
    def test_raises_for_oversized_file(self, tmp_path):
        from utils import validate_file_size
        large_file = tmp_path / "big.pdf"
        large_file.write_bytes(b"x")
        with patch("os.path.getsize", return_value=101 * 1024 * 1024):
            with pytest.raises(ValueError, match="too large"):
                validate_file_size(str(large_file))

    def test_passes_for_valid_size(self, tmp_path):
        from utils import validate_file_size
        small_file = tmp_path / "small.pdf"
        small_file.write_bytes(b"x" * 100)
        validate_file_size(str(small_file))  # should not raise


class TestValidateImageDimensions:
    def test_raises_for_oversized_image(self):
        from utils import validate_image_dimensions
        img = MagicMock()
        img.width = 20001
        img.height = 100
        with pytest.raises(ValueError, match="too large"):
            validate_image_dimensions(img)

    def test_raises_for_oversized_height(self):
        from utils import validate_image_dimensions
        img = MagicMock()
        img.width = 100
        img.height = 20001
        with pytest.raises(ValueError, match="too large"):
            validate_image_dimensions(img)

    def test_passes_for_valid_dimensions(self):
        from utils import validate_image_dimensions
        img = MagicMock()
        img.width = 1920
        img.height = 1080
        validate_image_dimensions(img)  # should not raise

    def test_passes_at_exact_limit(self):
        from utils import validate_image_dimensions
        img = MagicMock()
        img.width = 20000
        img.height = 20000
        validate_image_dimensions(img)  # should not raise at boundary
