"""PIL image watermarking logic and WatermarkParams dataclass."""

import io
import os
from dataclasses import dataclass
from PIL import Image, ImageDraw, ImageFont

from constants import PIL_COLOR_MAP, WATERMARK_ORIENTATION_MAP, JPEG_EXPORT_QUALITY
from utils import strip_image_metadata


@dataclass(frozen=True)
class WatermarkParams:
    """Immutable container for watermark rendering parameters."""
    text: str
    opacity: int
    font_size: int
    spacing: int
    color: str = "White"
    orientation: str = "Ascending (↗)"


def get_font(size: int) -> ImageFont.FreeTypeFont:
    """Try to load a system font, otherwise return the default font."""
    font_paths = [
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
    ]
    for path in font_paths:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                continue
    return ImageFont.load_default()


def apply_watermark_to_pil_image(img: Image.Image, params: WatermarkParams) -> Image.Image:
    """Apply a repeated diagonal watermark on a PIL image (RGBA).

    Args:
        img: PIL Image in RGBA mode
        params: WatermarkParams with text, opacity, font_size, spacing, color, orientation
    """
    if len(params.text) > 200:
        raise ValueError("Watermark text is too long (max 200 characters).")

    rgb = PIL_COLOR_MAP.get(params.color, (255, 255, 255))

    txt_layer = Image.new("RGBA", img.size, (rgb[0], rgb[1], rgb[2], 0))
    draw = ImageDraw.Draw(txt_layer)

    font = get_font(params.font_size)
    alpha = int((params.opacity / 100) * 255)
    fill_color = (rgb[0], rgb[1], rgb[2], alpha)

    # Get text bounding box with proper offset handling
    try:
        left, top, right, bottom = font.getbbox(params.text)
        txt_w = right - left
        txt_h = bottom - top
    except AttributeError:
        txt_w, txt_h = draw.textsize(params.text, font=font)
        left, top = 0, 0

    # Create stamp with proper size and draw text at correct position.
    # Account for bbox offsets to prevent text cutoff.
    padding = 20
    stamp_width, stamp_height = txt_w + padding, txt_h + padding
    stamp = Image.new("RGBA", (stamp_width, stamp_height), (255, 255, 255, 0))
    stamp_draw = ImageDraw.Draw(stamp)
    draw_x = padding // 2 - left
    draw_y = padding // 2 - top
    stamp_draw.text((draw_x, draw_y), params.text, font=font, fill=fill_color)

    rotation_angle = WATERMARK_ORIENTATION_MAP.get(params.orientation, 45)
    rotated_stamp = stamp.rotate(rotation_angle, expand=True, resample=Image.Resampling.BICUBIC)
    rotated_width, rotated_height = rotated_stamp.size

    for y in range(-rotated_height, img.height + rotated_height, params.spacing):
        for x in range(-rotated_width, img.width + rotated_width, params.spacing):
            offset = (params.spacing // 2) if (y // params.spacing) % 2 == 0 else 0
            txt_layer.paste(rotated_stamp, (x + offset, y), rotated_stamp)

    return Image.alpha_composite(img, txt_layer)


def apply_watermark(
    image_bytes: bytes,
    params: WatermarkParams,
    output_format: str = "JPEG",
) -> bytes:
    """Apply a repeated diagonal watermark to image bytes and return bytes."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    out = apply_watermark_to_pil_image(img, params)

    output = io.BytesIO()
    if output_format.upper() == "PNG":
        out_rgb = strip_image_metadata(out.convert("RGB"))
        out_rgb.save(output, format="PNG")
    else:
        out_rgb = strip_image_metadata(out.convert("RGB"))
        out_rgb.save(output, format="JPEG", quality=JPEG_EXPORT_QUALITY)
    return output.getvalue()
