from PIL import Image, ImageDraw, ImageFont
import io
import os
import fitz

# Constants for vector watermark
WATERMARK_COLOR_MAP = {
    "Blanc": (1.0, 1.0, 1.0),
    "Noir": (0.0, 0.0, 0.0),
    "Gris": (0.5, 0.5, 0.5),
}

# Orientation options: angle in degrees
# Ascending (↗): text goes from bottom-left to top-right
# Descending (↘): text goes from top-left to bottom-right
WATERMARK_ORIENTATION_MAP = {
    "Ascendant (↗)": 45,    # Counter-clockwise rotation
    "Descendant (↘)": -45,  # Clockwise rotation
}

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

def apply_watermark_to_pil_image(img, text, opacity, font_size, spacing, color="Blanc", orientation="Ascendant (↗)"):
    """Applique un filigrane répété en diagonale sur une image PIL (RGBA).

    Args:
        img: Image PIL en mode RGBA
        text: Texte du filigrane
        opacity: Opacité en pourcentage (0-100)
        font_size: Taille de la police en pixels
        spacing: Espacement entre les filigranes en pixels
        color: Couleur du texte ("Blanc", "Noir", "Gris")
        orientation: Direction du filigrane ("Ascendant (↗)" ou "Descendant (↘)")
    """
    # Mapping des couleurs
    color_map = {
        "Blanc": (255, 255, 255),
        "Noir": (0, 0, 0),
        "Gris": (128, 128, 128),
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

def apply_vector_watermark_to_pdf(doc, text, opacity, font_size, spacing, color, orientation="Ascendant (↗)"):
    """
    Applique un filigrane vectoriel natif sur toutes les pages du document PDF.

    Cette fonction utilise page.insert_text() de PyMuPDF pour ajouter des filigranes
    vectoriels qui préservent la qualité du PDF original. Le texte reste net à tout
    niveau de zoom et le contenu original reste sélectionnable.

    Args:
        doc (fitz.Document): Document PDF à filigraner
        text (str): Texte du filigrane (ex: "COPIE")
        opacity (int): Opacité en pourcentage (0-100)
        font_size (int): Taille de la police en points (12-72)
        spacing (int): Espacement entre les filigranes en pixels (50-300)
        color (str): Couleur du filigrane ("Blanc", "Noir", "Gris")
        orientation (str): Direction du filigrane ("Ascendant (↗)" ou "Descendant (↘)")

    Returns:
        None: Modifie le document en place

    Example:
        >>> doc = fitz.open("document.pdf")
        >>> apply_vector_watermark_to_pdf(
        ...     doc=doc,
        ...     text="CONFIDENTIEL",
        ...     opacity=30,
        ...     font_size=36,
        ...     spacing=150,
        ...     color="Blanc",
        ...     orientation="Ascendant (↗)"
        ... )
        >>> doc.save("document_watermarked.pdf")

    Notes:
        - Le filigrane est appliqué à toutes les pages du document
        - L'angle de rotation dépend de l'orientation choisie (45° ou -45°)
        - Le filigrane est ajouté en couche overlay (par-dessus le contenu)
        - La qualité du PDF original est préservée (pas de rasterisation)
        - Le texte original reste sélectionnable après filigranage
    """
    # Appliquer le filigrane à toutes les pages
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        apply_vector_watermark_to_page(page, text, opacity, font_size, spacing, color, orientation)

def apply_vector_watermark_to_page(page, text, opacity, font_size, spacing, color, orientation="Ascendant (↗)"):
    """
    Applique le filigrane vectoriel sur une seule page.

    Args:
        page: Page PyMuPDF
        text: Texte du filigrane
        opacity: Opacité en pourcentage (0-100)
        font_size: Taille de la police en points
        spacing: Espacement entre les filigranes en pixels
        color: Couleur du filigrane ("Blanc", "Noir", "Gris")
        orientation: Direction du filigrane ("Ascendant (↗)" ou "Descendant (↘)")
    """
    # Mapping de la couleur vers RGB (0.0-1.0 range pour PyMuPDF)
    rgb = WATERMARK_COLOR_MAP.get(color, (1.0, 1.0, 1.0))

    # Convertir opacité 0-100 en 0.0-1.0 (range PyMuPDF)
    fill_opacity = opacity / 100.0

    # Get rotation angle from orientation
    rotation_angle = WATERMARK_ORIENTATION_MAP.get(orientation, 45)

    # Dimensions de la page
    page_width = page.rect.width
    page_height = page.rect.height

    # Créer le motif de tiling diagonal
    y = -spacing
    row = 0

    while y < page_height + spacing:
        x = -spacing

        # Décaler les rangées alternées
        if row % 2 == 0:
            x += spacing // 2

        while x < page_width + spacing:
            point = fitz.Point(x, y)

            # Insérer le texte avec rotation et opacité
            page.insert_text(
                point=point,
                text=text,
                fontsize=font_size,
                fontname="helv",
                color=rgb,
                morph=(point, fitz.Matrix(rotation_angle)),
                fill_opacity=fill_opacity,
                overlay=True  # Dessiner par-dessus le contenu existant
            )

            x += spacing

        y += spacing
        row += 1

def apply_watermark_to_pdf(doc, watermark_params):
    """
    Applique un filigrane sur toutes les pages du document PDF.
    """
    text = watermark_params.get("text", "COPIE")
    opacity = watermark_params.get("opacity", 30)
    font_size = watermark_params.get("font_size", 36)
    spacing = watermark_params.get("spacing", 150)
    color = watermark_params.get("color", "Blanc")
    
    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        # On obtient la pixmap de la page
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        
        # Appliquer le filigrane
        watermarked_img = apply_watermark_to_pil_image(img.convert("RGBA"), text, opacity, font_size, spacing, color=color)
        
        # Conversion en bytes pour ré-insertion dans le PDF
        img_byte_arr = io.BytesIO()
        watermarked_img.convert("RGB").save(img_byte_arr, format='JPEG', quality=90)
        
        # Insérer l'image filigranée par-dessus la page
        page.insert_image(page.rect, stream=img_byte_arr.getvalue())

def save_watermarked_pdf(doc, output_path):
    """
    Sauvegarde le document PDF modifié.
    """
    doc.save(output_path)

def save_pdf_as_images(doc, output_dir, base_name):
    """
    Sauvegarde chaque page du PDF en tant qu'image JPG individuelle.
    """
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
        
    for i in range(len(doc)):
        page = doc.load_page(i)
        pix = page.get_pixmap()
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        
        # On peut réutiliser la pixmap directement si on ne veut pas refiligraner
        # Mais ici on suppose que apply_watermark_to_pdf a déjà été appelé sur doc.
        # Si on veut garantir la qualité 90, on passe par PIL.
        output_path = os.path.join(output_dir, f"{base_name}_page_{i+1:03d}.jpg")
        img.save(output_path, "JPEG", quality=90)

def generate_pdf_preview(doc, text, opacity, font_size, spacing, color, orientation="Ascendant (↗)"):
    """
    Génère un aperçu de la première page avec le filigrane vectoriel.
    Ne modifie pas le document original.
    Retourne les bytes de l'image (PNG).

    Args:
        doc: Document PyMuPDF
        text: Texte du filigrane
        opacity: Opacité en pourcentage (0-100)
        font_size: Taille de la police en points
        spacing: Espacement entre les filigranes en pixels
        color: Couleur du filigrane ("Blanc", "Noir", "Gris")
        orientation: Direction du filigrane ("Ascendant (↗)" ou "Descendant (↘)")
    """
    # Créer un document temporaire avec seulement la première page
    temp_doc = fitz.open()
    temp_doc.insert_pdf(doc, from_page=0, to_page=0)
    page = temp_doc.load_page(0)

    # Appliquer le filigrane avec l'orientation choisie
    apply_vector_watermark_to_page(page, text, opacity, font_size, spacing, color, orientation)

    # Rendu en image (PNG)
    pix = page.get_pixmap(alpha=True)
    return pix.tobytes("png")

def apply_secure_raster_watermark_to_pdf(doc, text, opacity, font_size, spacing, color, dpi=300, orientation="Ascendant (↗)"):
    """
    Applique un filigrane sur un PDF en rendant chaque page comme une image (rasterisation).
    Cela rend le filigrane indissociable du contenu original.

    Args:
        doc: Document PyMuPDF
        text: Texte du filigrane
        opacity: Opacité en pourcentage (0-100)
        font_size: Taille de la police en points
        spacing: Espacement entre les filigranes en pixels
        color: Couleur du filigrane ("Blanc", "Noir", "Gris")
        dpi: Résolution en DPI (300, 450, ou 600)
        orientation: Direction du filigrane ("Ascendant (↗)" ou "Descendant (↘)")
    """
    out_doc = fitz.open()

    # On définit une matrice pour le DPI
    # get_pixmap utilise par défaut 72 DPI. Pour avoir le DPI souhaité, on scale par DPI / 72.
    zoom = dpi / 72
    mat = fitz.Matrix(zoom, zoom)

    for page in doc:
        # 1. Rendre la page originale en image (PixMap) à haute résolution
        pix = page.get_pixmap(matrix=mat, alpha=False)

        # 2. Convertir en image PIL
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)

        # 3. Convertir en RGBA pour appliquer le filigrane (le tiling utilise alpha_composite)
        img_rgba = img.convert("RGBA")

        # 4. Appliquer le filigrane (le tiling doit être adapté à la résolution élevée)
        # On ajuste la taille de police et l'espacement proportionnellement au DPI
        # pour garder le même aspect visuel relatif que sur la prévisualisation standard.
        scale_factor = dpi / 72
        adjusted_font_size = int(font_size * scale_factor)
        adjusted_spacing = int(spacing * scale_factor)

        watermarked_img = apply_watermark_to_pil_image(
            img_rgba, text, opacity, adjusted_font_size, adjusted_spacing,
            color=color, orientation=orientation
        )

        # 5. Reconvertir en RGB pour l'insérer dans le nouveau PDF
        final_img = watermarked_img.convert("RGB")

        # 6. Créer une nouvelle page dans le document de sortie avec les dimensions originales
        new_page = out_doc.new_page(width=page.rect.width, height=page.rect.height)

        # 7. Insérer l'image dans la nouvelle page
        img_buffer = io.BytesIO()
        final_img.save(img_buffer, format="JPEG", quality=95)  # Qualité maintenue à 95%
        new_page.insert_image(new_page.rect, stream=img_buffer.getvalue())

    return out_doc

