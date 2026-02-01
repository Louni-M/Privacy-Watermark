import pytest
import io
from PIL import Image
from main import apply_watermark

def test_apply_watermark_returns_bytes():
    # Create a small test image
    img = Image.new("RGB", (100, 100), color="white")
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')
    
    # Execute
    result_bytes = apply_watermark(img_byte_arr.getvalue(), "TEST", 30, 20, 50)
    
    # Verify
    assert isinstance(result_bytes, bytes)
    result_img = Image.open(io.BytesIO(result_bytes))
    assert result_img.size == (100, 100)
    assert result_img.mode in ("RGB", "RGBA")

def test_apply_watermark_opacity():
    # This is a bit hard to test precisely without pixel analysis, 
    # but we can check if the result is different from the original.
    img = Image.new("RGB", (100, 100), color="white")
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')
    original_bytes = img_byte_arr.getvalue()
    
    # Execute with high opacity
    watermarked_bytes = apply_watermark(original_bytes, "TEST", 100, 20, 10)
    
    # Verify they are different
    assert watermarked_bytes != original_bytes
