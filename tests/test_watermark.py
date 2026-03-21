"""Tests for watermark.py: WatermarkParams dataclass and PIL watermark logic."""
import io
import pytest
from PIL import Image
from unittest.mock import patch


class TestWatermarkParams:
    def test_default_values(self):
        from watermark import WatermarkParams
        params = WatermarkParams(text="COPY", opacity=30, font_size=36, spacing=150)
        assert params.color == "White"
        assert params.orientation == "Ascending (↗)"

    def test_custom_values(self):
        from watermark import WatermarkParams
        params = WatermarkParams(
            text="TEST", opacity=50, font_size=24, spacing=100,
            color="Black", orientation="Descending (↘)"
        )
        assert params.text == "TEST"
        assert params.opacity == 50
        assert params.font_size == 24
        assert params.spacing == 100
        assert params.color == "Black"
        assert params.orientation == "Descending (↘)"

    def test_is_frozen(self):
        from watermark import WatermarkParams
        params = WatermarkParams(text="COPY", opacity=30, font_size=36, spacing=150)
        with pytest.raises((AttributeError, TypeError)):
            params.text = "CHANGED"

    def test_equality(self):
        from watermark import WatermarkParams
        p1 = WatermarkParams(text="X", opacity=10, font_size=12, spacing=50)
        p2 = WatermarkParams(text="X", opacity=10, font_size=12, spacing=50)
        assert p1 == p2

    def test_all_fields_required_except_defaults(self):
        from watermark import WatermarkParams
        with pytest.raises(TypeError):
            WatermarkParams()  # missing required fields


class TestGetFont:
    def test_returns_font_object(self):
        from watermark import get_font
        from PIL import ImageFont
        font = get_font(36)
        assert font is not None

    def test_falls_back_to_default_if_no_system_font(self):
        from watermark import get_font
        from PIL import ImageFont
        with patch("os.path.exists", return_value=False):
            font = get_font(36)
        assert font is not None


class TestApplyWatermarkToPilImage:
    @pytest.fixture
    def rgba_image(self):
        return Image.new("RGBA", (300, 300), (255, 255, 255, 255))

    def test_returns_rgba_image(self, rgba_image):
        from watermark import apply_watermark_to_pil_image
        from watermark import WatermarkParams
        params = WatermarkParams(text="TEST", opacity=30, font_size=24, spacing=100)
        result = apply_watermark_to_pil_image(rgba_image, params)
        assert result.mode == "RGBA"

    def test_output_same_size(self, rgba_image):
        from watermark import apply_watermark_to_pil_image
        from watermark import WatermarkParams
        params = WatermarkParams(text="COPY", opacity=50, font_size=36, spacing=150)
        result = apply_watermark_to_pil_image(rgba_image, params)
        assert result.size == rgba_image.size

    def test_rejects_text_over_200_chars(self, rgba_image):
        from watermark import apply_watermark_to_pil_image
        from watermark import WatermarkParams
        params = WatermarkParams(text="A" * 201, opacity=30, font_size=36, spacing=150)
        with pytest.raises(ValueError, match="too long"):
            apply_watermark_to_pil_image(rgba_image, params)

    def test_all_colors(self, rgba_image):
        from watermark import apply_watermark_to_pil_image
        from watermark import WatermarkParams
        for color in ("White", "Black", "Gray"):
            params = WatermarkParams(text="X", opacity=50, font_size=24, spacing=100, color=color)
            result = apply_watermark_to_pil_image(rgba_image, params)
            assert result.mode == "RGBA"

    def test_all_orientations(self, rgba_image):
        from watermark import apply_watermark_to_pil_image
        from watermark import WatermarkParams
        for orientation in ("Ascending (↗)", "Descending (↘)"):
            params = WatermarkParams(text="X", opacity=50, font_size=24, spacing=100, orientation=orientation)
            result = apply_watermark_to_pil_image(rgba_image, params)
            assert result.mode == "RGBA"

    def test_changes_pixels(self, rgba_image):
        from watermark import apply_watermark_to_pil_image
        from watermark import WatermarkParams
        params = WatermarkParams(text="VISIBLE", opacity=100, font_size=36, spacing=80, color="Black")
        result = apply_watermark_to_pil_image(rgba_image, params)
        # With 100% opacity black text on white, some pixels must have changed
        original_pixels = list(rgba_image.get_flattened_data())
        result_pixels = list(result.get_flattened_data())
        assert original_pixels != result_pixels


class TestApplyWatermarkFunction:
    """Test the top-level apply_watermark() function (image bytes in/out)."""

    def test_returns_bytes(self):
        from watermark import apply_watermark, WatermarkParams
        img = Image.new("RGB", (100, 100), color="blue")
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        params = WatermarkParams(text="TEST", opacity=30, font_size=24, spacing=80)
        result = apply_watermark(buf.getvalue(), params)
        assert isinstance(result, bytes)

    def test_output_dimensions_preserved(self):
        from watermark import apply_watermark, WatermarkParams
        img = Image.new("RGB", (200, 150), color="red")
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        params = WatermarkParams(text="X", opacity=30, font_size=24, spacing=80)
        result_bytes = apply_watermark(buf.getvalue(), params)
        result_img = Image.open(io.BytesIO(result_bytes))
        assert result_img.size == (200, 150)

    def test_png_output_format(self):
        from watermark import apply_watermark, WatermarkParams
        img = Image.new("RGB", (100, 100), color="green")
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        params = WatermarkParams(text="X", opacity=30, font_size=24, spacing=80)
        result_bytes = apply_watermark(buf.getvalue(), params, output_format="PNG")
        result_img = Image.open(io.BytesIO(result_bytes))
        assert result_img.format == "PNG"


class TestGetFont:
    def test_returns_freetype_font(self):
        from watermark import get_font
        font = get_font(24)
        from PIL import ImageFont
        assert isinstance(font, ImageFont.FreeTypeFont)

    def test_different_sizes_produce_different_fonts(self):
        from watermark import get_font
        font_small = get_font(12)
        font_large = get_font(72)
        # Different sizes should return different font objects
        assert font_small.size != font_large.size
