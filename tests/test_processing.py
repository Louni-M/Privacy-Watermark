import io
from PIL import Image
from watermark import apply_watermark, WatermarkParams

def test_apply_watermark_returns_bytes():
    img = Image.new("RGB", (100, 100), color="white")
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')

    params = WatermarkParams(text="TEST", opacity=30, font_size=20, spacing=50)
    result_bytes = apply_watermark(img_byte_arr.getvalue(), params)

    assert isinstance(result_bytes, bytes)
    result_img = Image.open(io.BytesIO(result_bytes))
    assert result_img.size == (100, 100)
    assert result_img.mode in ("RGB", "RGBA")

def test_apply_watermark_opacity():
    img = Image.new("RGB", (100, 100), color="white")
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')
    original_bytes = img_byte_arr.getvalue()

    params = WatermarkParams(text="TEST", opacity=100, font_size=20, spacing=10)
    watermarked_bytes = apply_watermark(original_bytes, params)

    assert watermarked_bytes != original_bytes
