from PIL import Image, ImageDraw, ImageFont
import io
import os
import fitz

def load_pdf(file_path):
    """
    Charge un fichier PDF et retourne le document et le nombre de pages.
    Lève une exception si le PDF est protégé ou invalide.
    """
    try:
        doc = fitz.open(file_path)
        if doc.is_encrypted:
             raise Exception("Ce PDF est protégé par mot de passe et ne peut pas être ouvert.")
        if doc.page_count == 0:
             raise Exception("Impossible de lire ce fichier PDF (aucune page).")
        return doc, doc.page_count
    except fitz.FileDataError:
        raise Exception("Impossible de lire ce fichier PDF.")
    except Exception as e:
        if "protégé" in str(e):
            raise e
        raise Exception(f"Erreur lors du chargement du PDF : {e}")

def pdf_page_to_image(doc, page_num):
    """
    Convertit une page PDF en image PIL pour la prévisualisation.
    """
    page = doc.load_page(page_num)
    pix = page.get_pixmap(alpha=True)
    img = Image.frombytes("RGBA", [pix.width, pix.height], pix.samples)
    return img

def get_font(size):
    """Essaye de charger une police système, sinon retourne la police par défaut."""
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

def apply_watermark_to_pil_image(img, text, opacity, font_size, spacing):
    """Applique un filigrane répété en diagonale sur une image PIL (RGBA)."""
    txt_layer = Image.new("RGBA", img.size, (255, 255, 255, 0))
    d = ImageDraw.Draw(txt_layer)
    
    font = get_font(font_size)
    alpha = int((opacity / 100) * 255)
    fill_color = (255, 255, 255, alpha)
    
    try:
        left, top, right, bottom = font.getbbox(text)
        txt_w = right - left
        txt_h = bottom - top
    except AttributeError:
        txt_w, txt_h = d.textsize(text, font=font)
    
    padding = 20
    sw, sh = txt_w + padding, txt_h + padding
    stamp = Image.new("RGBA", (sw, sh), (255, 255, 255, 0))
    sd = ImageDraw.Draw(stamp)
    sd.text((padding//2, padding//2), text, font=font, fill=fill_color)
    
    rotated_stamp = stamp.rotate(45, expand=True, resample=Image.Resampling.BICUBIC)
    rw, rh = rotated_stamp.size
    
    for y in range(-rh, img.height + rh, spacing):
        for x in range(-rw, img.width + rw, spacing):
            offset = (spacing // 2) if (y // spacing) % 2 == 0 else 0
            txt_layer.paste(rotated_stamp, (x + offset, y), rotated_stamp)
            
    return Image.alpha_composite(img, txt_layer)

def apply_watermark_to_pdf(doc, watermark_params):
    """
    Applique un filigrane sur toutes les pages du document PDF.
    """
    text = watermark_params.get("text", "COPIE")
    opacity = watermark_params.get("opacity", 30)
    font_size = watermark_params.get("font_size", 36)
    spacing = watermark_params.get("spacing", 150)
    
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        # On obtient la pixmap de la page
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        
        # Appliquer le filigrane
        watermarked_img = apply_watermark_to_pil_image(img.convert("RGBA"), text, opacity, font_size, spacing)
        
        # Conversion en bytes pour ré-insertion dans le PDF
        img_byte_arr = io.BytesIO()
        watermarked_img.convert("RGB").save(img_byte_arr, format='JPEG', quality=90)
        
        # Insérer l'image filigranée par-dessus la page
        page.insert_image(page.rect, stream=img_byte_arr.getvalue())
