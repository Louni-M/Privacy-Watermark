"""Shared utility functions for Passport Filigrane."""

import os
import sys
from PIL import Image

from constants import MAX_FILE_SIZE_BYTES, MAX_IMAGE_DIMENSION


def get_log_path() -> str:
    """Return a secure, platform-appropriate log file path."""
    if sys.platform == "darwin":
        log_dir = os.path.expanduser("~/Library/Logs/PassportFiligrane")
    elif sys.platform == "win32":
        log_dir = os.path.join(
            os.environ.get("APPDATA", os.path.expanduser("~")),
            "PassportFiligrane", "Logs"
        )
    else:
        log_dir = os.path.join(
            os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")),
            "PassportFiligrane"
        )

    os.makedirs(log_dir, mode=0o700, exist_ok=True)
    return os.path.join(log_dir, "error_log.txt")


def sanitize_path_for_log(message: str) -> str:
    """Remove potential file paths and control characters from log messages."""
    home = os.path.expanduser("~")
    sanitized = message.replace(home, "~USER")
    sanitized = sanitized.replace("\n", " ").replace("\r", " ")
    return sanitized


def strip_image_metadata(img: Image.Image) -> Image.Image:
    """Return a clean copy of a PIL Image with all EXIF/metadata stripped."""
    clean = Image.new(img.mode, img.size)
    clean.paste(img, (0, 0))
    return clean


def detect_file_type(file_path: str) -> str:
    """Determine whether the file is an image or a PDF."""
    ext = os.path.splitext(file_path)[1].lower()
    if ext in [".jpg", ".jpeg", ".png"]:
        return "image"
    elif ext == ".pdf":
        return "pdf"
    return "unknown"


def validate_file_size(file_path: str) -> None:
    """Check that a file does not exceed the maximum allowed size."""
    size = os.path.getsize(file_path)
    if size > MAX_FILE_SIZE_BYTES:
        size_mb = size / (1024 * 1024)
        raise ValueError(
            f"File too large ({size_mb:.1f} MB). "
            f"Maximum allowed size is {MAX_FILE_SIZE_BYTES // (1024 * 1024)} MB."
        )


def validate_image_dimensions(img) -> None:
    """Check that an image's dimensions are within safe limits."""
    if img.width > MAX_IMAGE_DIMENSION or img.height > MAX_IMAGE_DIMENSION:
        raise ValueError(
            f"Image too large ({img.width}x{img.height} px). "
            f"Maximum allowed is {MAX_IMAGE_DIMENSION}x{MAX_IMAGE_DIMENSION} px."
        )
