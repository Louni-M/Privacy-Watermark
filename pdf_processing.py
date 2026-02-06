from PIL import Image, ImageDraw, ImageFont
import io
import os
import fitz

# Constants for vector watermark
WATERMARK_COLOR_MAP = {
    "White": (1.0, 1.0, 1.0),
    "Black": (0.0, 0.0, 0.0),
    "Gray": (0.5, 0.5, 0.5),
}

# Orientation options: angle in degrees
# Ascending (↗): text goes from bottom-left to top-right
# Descending (↘): text goes from top-left to bottom-right
WATERMARK_ORIENTATION_MAP = {
    "Ascending (↗)": 45,    # Counter-clockwise rotation
    "Descending (↘)": -45,  # Clockwise rotation
}

def load_pdf(file_path):
    """
    Load a PDF file and return the document and the number of pages.
    Raises an exception if the PDF is protected or invalid.
    """
    try:
        doc = fitz.open(file_path)
        if doc.is_encrypted:
             raise Exception("This PDF is password-protected and cannot be opened.")
        if doc.page_count == 0:
             raise Exception("Unable to read this PDF file (no pages).")
        return doc, doc.page_count
    except fitz.FileDataError:
        raise Exception("Unable to read this PDF file.")
    except Exception as e:
        if "password-protected" in str(e):
            raise e
        raise Exception(f"Error loading PDF: {e}")

def pdf_page_to_image(doc, page_num):
    """
    Convert a PDF page to a PIL image for preview.
    """
    page = doc.load_page(page_num)
    pix = page.get_pixmap(alpha=True)
    img = Image.frombytes("RGBA", [pix.width, pix.height], pix.samples)
    return img

def get_font(size):
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

def apply_watermark_to_pil_image(img, text, opacity, font_size, spacing, color="White", orientation="Ascending (↗)"):
    """Apply a repeated diagonal watermark on a PIL image (RGBA).

    Args:
        img: PIL Image in RGBA mode
        text: Watermark text
        opacity: Opacity as a percentage (0-100)
        font_size: Font size in pixels
        spacing: Spacing between watermarks in pixels
        color: Text color ("White", "Black", "Gray")
        orientation: Watermark direction ("Ascending (↗)" or "Descending (↘)")
    """
    color_map = {
        "White": (255, 255, 255),
        "Black": (0, 0, 0),
        "Gray": (128, 128, 128),
    }
    rgb = color_map.get(color, (255, 255, 255))

    txt_layer = Image.new("RGBA", img.size, (rgb[0], rgb[1], rgb[2], 0))
    d = ImageDraw.Draw(txt_layer)

    font = get_font(font_size)
    alpha = int((opacity / 100) * 255)
    fill_color = (rgb[0], rgb[1], rgb[2], alpha)

    # Get text bounding box with proper offset handling
    try:
        left, top, right, bottom = font.getbbox(text)
        txt_w = right - left
        txt_h = bottom - top
    except AttributeError:
        txt_w, txt_h = d.textsize(text, font=font)
        left, top = 0, 0

    # Create stamp with proper size and draw text at correct position
    # Account for bbox offsets to prevent text cutoff
    padding = 20
    sw, sh = txt_w + padding, txt_h + padding
    stamp = Image.new("RGBA", (sw, sh), (255, 255, 255, 0))
    sd = ImageDraw.Draw(stamp)
    # Draw at position that accounts for font metrics (top offset)
    draw_x = padding // 2 - left
    draw_y = padding // 2 - top
    sd.text((draw_x, draw_y), text, font=font, fill=fill_color)

    # Get rotation angle from orientation
    rotation_angle = WATERMARK_ORIENTATION_MAP.get(orientation, 45)
    rotated_stamp = stamp.rotate(rotation_angle, expand=True, resample=Image.Resampling.BICUBIC)
    rw, rh = rotated_stamp.size

    for y in range(-rh, img.height + rh, spacing):
        for x in range(-rw, img.width + rw, spacing):
            offset = (spacing // 2) if (y // spacing) % 2 == 0 else 0
            txt_layer.paste(rotated_stamp, (x + offset, y), rotated_stamp)

    return Image.alpha_composite(img, txt_layer)

def apply_vector_watermark_to_pdf(doc, text, opacity, font_size, spacing, color, orientation="Ascending (↗)"):
    """
    Apply a native vector watermark on all pages of the PDF document.

    Uses page.insert_text() from PyMuPDF to add vector watermarks that preserve
    the quality of the original PDF. Text remains sharp at any zoom level and
    the original content stays selectable.

    Args:
        doc (fitz.Document): PDF document to watermark
        text (str): Watermark text (e.g. "COPY")
        opacity (int): Opacity as a percentage (0-100)
        font_size (int): Font size in points (12-72)
        spacing (int): Spacing between watermarks in pixels (50-300)
        color (str): Watermark color ("White", "Black", "Gray")
        orientation (str): Watermark direction ("Ascending (↗)" or "Descending (↘)")

    Returns:
        None: Modifies the document in place
    """
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        apply_vector_watermark_to_page(page, text, opacity, font_size, spacing, color, orientation)

def apply_vector_watermark_to_page(page, text, opacity, font_size, spacing, color, orientation="Ascending (↗)"):
    """
    Apply a vector watermark on a single page.

    Args:
        page: PyMuPDF page
        text: Watermark text
        opacity: Opacity as a percentage (0-100)
        font_size: Font size in points
        spacing: Spacing between watermarks in pixels
        color: Watermark color ("White", "Black", "Gray")
        orientation: Watermark direction ("Ascending (↗)" or "Descending (↘)")
    """
    rgb = WATERMARK_COLOR_MAP.get(color, (1.0, 1.0, 1.0))

    # Convert opacity 0-100 to 0.0-1.0 (PyMuPDF range)
    fill_opacity = opacity / 100.0

    # Get rotation angle from orientation
    rotation_angle = WATERMARK_ORIENTATION_MAP.get(orientation, 45)

    page_width = page.rect.width
    page_height = page.rect.height

    # Create diagonal tiling pattern
    y = -spacing
    row = 0

    while y < page_height + spacing:
        x = -spacing

        # Offset alternating rows
        if row % 2 == 0:
            x += spacing // 2

        while x < page_width + spacing:
            point = fitz.Point(x, y)

            # Insert text with rotation and opacity
            page.insert_text(
                point=point,
                text=text,
                fontsize=font_size,
                fontname="helv",
                color=rgb,
                morph=(point, fitz.Matrix(rotation_angle)),
                fill_opacity=fill_opacity,
                overlay=True  # Draw on top of existing content
            )

            x += spacing

        y += spacing
        row += 1

def apply_watermark_to_pdf(doc, watermark_params):
    """
    Apply a watermark on all pages of the PDF document.
    """
    text = watermark_params.get("text", "COPY")
    opacity = watermark_params.get("opacity", 30)
    font_size = watermark_params.get("font_size", 36)
    spacing = watermark_params.get("spacing", 150)
    color = watermark_params.get("color", "White")

    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        # Apply watermark
        watermarked_img = apply_watermark_to_pil_image(img.convert("RGBA"), text, opacity, font_size, spacing, color=color)

        # Convert to bytes for re-insertion into the PDF
        img_byte_arr = io.BytesIO()
        watermarked_img.convert("RGB").save(img_byte_arr, format='JPEG', quality=90)

        # Insert watermarked image on top of the page
        page.insert_image(page.rect, stream=img_byte_arr.getvalue())

def save_watermarked_pdf(doc, output_path):
    """
    Save the modified PDF document.
    """
    doc.save(output_path)

def save_pdf_as_images(doc, output_dir, base_name, img_format="JPEG"):
    """
    Save each page of the PDF as an individual image (JPG or PNG).
    Output images are created from raw pixel data (no EXIF metadata).
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for i in range(len(doc)):
        page = doc.load_page(i)
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        ext = "png" if img_format.upper() == "PNG" else "jpg"
        pil_fmt = "PNG" if img_format.upper() == "PNG" else "JPEG"
        output_path = os.path.join(output_dir, f"{base_name}_page_{i+1:03d}.{ext}")
        
        if pil_fmt == "JPEG":
            img.save(output_path, pil_fmt, quality=90)
        else:
            img.save(output_path, pil_fmt)

def generate_pdf_preview(doc, text, opacity, font_size, spacing, color, orientation="Ascending (↗)"):
    """
    Generate a preview of the first page with the vector watermark.
    Does not modify the original document.
    Returns the image bytes (PNG).

    Args:
        doc: PyMuPDF document
        text: Watermark text
        opacity: Opacity as a percentage (0-100)
        font_size: Font size in points
        spacing: Spacing between watermarks in pixels
        color: Watermark color ("White", "Black", "Gray")
        orientation: Watermark direction ("Ascending (↗)" or "Descending (↘)")
    """
    # Create a temporary document with only the first page
    temp_doc = fitz.open()
    temp_doc.insert_pdf(doc, from_page=0, to_page=0)
    page = temp_doc.load_page(0)

    # Apply watermark with chosen orientation
    apply_vector_watermark_to_page(page, text, opacity, font_size, spacing, color, orientation)

    # Render to image (PNG)
    pix = page.get_pixmap(alpha=True)
    return pix.tobytes("png")

def apply_secure_raster_watermark_to_pdf(doc, text, opacity, font_size, spacing, color, dpi=300, orientation="Ascending (↗)"):
    """
    Apply a watermark on a PDF by rendering each page as an image (rasterization).
    This makes the watermark inseparable from the original content.

    Args:
        doc: PyMuPDF document
        text: Watermark text
        opacity: Opacity as a percentage (0-100)
        font_size: Font size in points
        spacing: Spacing between watermarks in pixels
        color: Watermark color ("White", "Black", "Gray")
        dpi: Resolution in DPI (300, 450, or 600)
        orientation: Watermark direction ("Ascending (↗)" or "Descending (↘)")
    """
    out_doc = fitz.open()

    # Define a matrix for the DPI
    # get_pixmap uses 72 DPI by default. To get the desired DPI, scale by DPI / 72.
    zoom = dpi / 72
    mat = fitz.Matrix(zoom, zoom)

    for page in doc:
        # 1. Render the original page as a high-resolution image (PixMap)
        pix = page.get_pixmap(matrix=mat, alpha=False)

        # 2. Convert to PIL image
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        # 3. Convert to RGBA to apply the watermark (tiling uses alpha_composite)
        img_rgba = img.convert("RGBA")

        # 4. Apply the watermark (tiling must be adapted to the high resolution)
        # Adjust font size and spacing proportionally to the DPI
        # to keep the same visual appearance as in the standard preview.
        scale_factor = dpi / 72
        adjusted_font_size = int(font_size * scale_factor)
        adjusted_spacing = int(spacing * scale_factor)

        watermarked_img = apply_watermark_to_pil_image(
            img_rgba, text, opacity, adjusted_font_size, adjusted_spacing,
            color=color, orientation=orientation
        )

        # 5. Convert back to RGB for insertion into the new PDF
        final_img = watermarked_img.convert("RGB")

        # 6. Create a new page in the output document with original dimensions
        new_page = out_doc.new_page(width=page.rect.width, height=page.rect.height)

        # 7. Insert the image into the new page
        img_buffer = io.BytesIO()
        final_img.save(img_buffer, format="JPEG", quality=95)
        new_page.insert_image(new_page.rect, stream=img_buffer.getvalue())

    return out_doc
