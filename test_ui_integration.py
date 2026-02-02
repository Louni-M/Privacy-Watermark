import pytest
import os
from main import detect_file_type

def test_detect_file_type_images():
    assert detect_file_type("test.jpg") == "image"
    assert detect_file_type("image.JPEG") == "image"
    assert detect_file_type("photo.png") == "image"

def test_detect_file_type_pdf():
    assert detect_file_type("document.pdf") == "pdf"
    assert detect_file_type("DOC.PDF") == "pdf"

def test_detect_file_type_unknown():
    assert detect_file_type("file.txt") == "unknown"
    assert detect_file_type("no_extension") == "unknown"
