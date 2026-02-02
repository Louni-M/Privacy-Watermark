import flet as ft
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import os
import threading
from pdf_processing import load_pdf, pdf_page_to_image, apply_watermark_to_pdf  # New import

def generate_preview(image_bytes_io):
    """Génère un thumbnail de l'image (max 800px) pour la prévisualisation."""
    img = Image.open(image_bytes_io)
    
    # Calcul du ratio pour redimensionnement (max 800px)
    max_size = 800
    if img.width > max_size or img.height > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    
    # Conversion en bytes pour Flet
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')
    return img_byte_arr.getvalue()

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

def apply_watermark(image_bytes, text, opacity, font_size, spacing):
    """Applique un filigrane répété en diagonale sur l'image."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    txt_layer = Image.new("RGBA", img.size, (255, 255, 255, 0))
    d = ImageDraw.Draw(txt_layer)
    
    font = get_font(font_size)
    
    # Couleur du texte avec opacité (0-255)
    # On mappe 0-100 (user) -> 0-255 (alpha)
    alpha = int((opacity / 100) * 255)
    fill_color = (255, 255, 255, alpha)
    
    # Création d'une petite image pour le texte pivoté
    # On calcule la taille du texte
    try:
        left, top, right, bottom = font.getbbox(text)
        txt_w = right - left
        txt_h = bottom - top
    except AttributeError: # Fallback pour anciennes versions de Pillow
        txt_w, txt_h = d.textsize(text, font=font)
    
    # Créer un canvas pour un seul texte pivoté
    # On prend une marge pour la rotation
    padding = 20
    sw, sh = txt_w + padding, txt_h + padding
    stamp = Image.new("RGBA", (sw, sh), (255, 255, 255, 0))
    sd = ImageDraw.Draw(stamp)
    sd.text((padding//2, padding//2), text, font=font, fill=fill_color)
    
    # Rotation
    rotated_stamp = stamp.rotate(45, expand=True, resample=Image.Resampling.BICUBIC)
    rw, rh = rotated_stamp.size
    
    # Tiling (Répétition)
    for y in range(-rh, img.height + rh, spacing):
        for x in range(-rw, img.width + rw, spacing):
            # Décalage d'une ligne sur deux pour un effet "quinconce"
            offset = (spacing // 2) if (y // spacing) % 2 == 0 else 0
            txt_layer.paste(rotated_stamp, (x + offset, y), rotated_stamp)
            
    # Fusion
    out = Image.alpha_composite(img, txt_layer)
    
    # Retour en bytes (PNG pour garder la transparence si besoin, ou JPEG si on veut compresser)
    output = io.BytesIO()
    # On reconvertit en RGB pour la sortie si l'original était RGB (optionnel)
    out.convert("RGB").save(output, format="JPEG", quality=90)
    return output.getvalue()

def detect_file_type(file_path):
    """
    Détermine si le fichier est une image ou un PDF en fonction de son extension.
    """
    ext = os.path.splitext(file_path)[1].lower()
    if ext in ['.jpg', '.jpeg', '.png']:
        return "image"
    elif ext == '.pdf':
        return "pdf"
    return "unknown"

def main(page: ft.Page):
    """
    Point d'entrée principal de l'application Flet.
    Gère le layout, les événements et l'état de l'interface.
    """
    page.title = "Passport Filigrane"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#1a1a1a"

    # --- État de l'application ---
    original_image_bytes = None
    watermarked_image_bytes = None
    pdf_doc = None
    current_file_type = None
    num_pages = 0
    update_timer = None

    # --- Composants UI ---
    
    # Zone d'image pour la prévisualisation
    preview_image = ft.Image(
        src_base64="",
        fit="contain",
        visible=False,
    )

    file_info_text = ft.Text("", size=12, color="#aaaaaa", italic=True, visible=False)
    
    export_format_dropdown = ft.Dropdown(
        label="Format d'export",
        label_style=ft.TextStyle(color="#ffffff", size=14),
        options=[
            ft.dropdown.Option("PDF", "PDF"),
            ft.dropdown.Option("Images (JPG)", "Images"),
        ],
        value="PDF",
        visible=False,
        on_change=lambda _: page.update()
    )

    def set_controls_disabled(disabled: bool):
        """Active ou désactive tous les contrôles de filigrane."""
        watermark_text.disabled = disabled
        opacity_slider.disabled = disabled
        font_size_slider.disabled = disabled
        spacing_slider.disabled = disabled
        save_button.disabled = disabled or watermarked_image_bytes is None
        page.update()

    def update_preview(e=None):
        """Déclenche la mise à jour du filigrane avec un debounce."""
        nonlocal original_image_bytes, watermarked_image_bytes, update_timer, pdf_doc, current_file_type
        
        # Mise à jour immédiate des labels (pour la réactivité UI)
        opacity_label.value = f"Opacité ({int(opacity_slider.value)}%)"
        font_size_label.value = f"Taille de police ({int(font_size_slider.value)} px)"
        spacing_label.value = f"Espacement ({int(spacing_slider.value)} px)"
        page.update()

        if current_file_type is None:
            return
            
        if update_timer:
            update_timer.cancel()
            
        def do_update():
            nonlocal watermarked_image_bytes
            try:
                # Récupération des valeurs des contrôles
                text = watermark_text.value
                opacity = opacity_slider.value
                font_size = int(font_size_slider.value)
                spacing = int(spacing_slider.value)
                
                if current_file_type == "image":
                    # Application du filigrane sur image
                    watermarked_image_bytes = apply_watermark(original_image_bytes, text, opacity, font_size, spacing)
                elif current_file_type == "pdf" and pdf_doc:
                    # Pour la prévisualisation PDF, on ne filigrane que la première page
                    from pdf_processing import apply_watermark_to_pil_image
                    
                    # On convertit la première page en image
                    first_page_img = pdf_page_to_image(pdf_doc, 0)
                    
                    # On y applique le filigrane
                    watermarked_img = apply_watermark_to_pil_image(first_page_img, text, opacity, font_size, spacing)
                    
                    # On convertit en bytes pour l'affichage
                    buffer = io.BytesIO()
                    watermarked_img.convert("RGB").save(buffer, format="JPEG", quality=90)
                    watermarked_image_bytes = buffer.getvalue()
                
                # Mise à jour de la prévisualisation
                preview_image.src_base64 = base64.b64encode(watermarked_image_bytes).decode("utf-8")
                preview_image.update()
                
                # Activer le bouton de sauvegarde
                save_button.disabled = False
                save_button.update()
            except Exception as ex:
                show_error(f"Erreur de mise à jour : {ex}")

        # Debounce de 200ms
        update_timer = threading.Timer(0.2, do_update)
        update_timer.start()

    def show_error(message: str):
        """Affiche un message d'erreur via SnackBar."""
        page.snack_bar = ft.SnackBar(ft.Text(message), bgcolor=ft.colors.ERROR)
        page.snack_bar.open = True
        page.update()

    def on_file_result(e: ft.FilePickerResultEvent):
        """Gère le résultat de la sélection de fichier."""
        nonlocal original_image_bytes, pdf_doc, current_file_type, num_pages
        if e.files:
            file_path = e.files[0].path
            if not file_path:
                return
                
            try:
                # Détection du type de fichier
                current_file_type = detect_file_type(file_path)
                
                if current_file_type == "image":
                    with open(file_path, "rb") as f:
                        content = f.read()
                    
                    # Vérification Pillow
                    try:
                        Image.open(io.BytesIO(content)).verify()
                    except Exception:
                        show_error("Le fichier n'est pas une image valide.")
                        return
                    
                    original_image_bytes = content
                    pdf_doc = None
                    file_info_text.value = "Image chargée"
                    export_format_dropdown.visible = False
                    
                elif current_file_type == "pdf":
                    # Chargement via pdf_processing
                    try:
                        pdf_doc, num_pages = load_pdf(file_path)
                    except Exception as ex:
                        show_error(str(ex))
                        return
                    
                    original_image_bytes = None
                    file_info_text.value = f"PDF chargé ({num_pages} pages)"
                    export_format_dropdown.visible = True
                
                else:
                    show_error("Type de fichier non supporté.")
                    return
                
                file_info_text.visible = True
                set_controls_disabled(False)
                update_preview()
                preview_image.visible = True
                page.update()
            except PermissionError:
                show_error("Permission refusée lors de l'ouverture du fichier.")
            except Exception as ex:
                show_error(f"Erreur lors du chargement : {ex}")
        else:
            print("Selection cancelled")

    def on_save_result(e: ft.FilePickerResultEvent):
        """Gère le résultat du dialogue de sauvegarde."""
        if e.path and watermarked_image_bytes:
            try:
                with open(e.path, "wb") as f:
                    f.write(watermarked_image_bytes)
                page.snack_bar = ft.SnackBar(
                    ft.Text(f"Image enregistrée : {os.path.basename(e.path)}"),
                    bgcolor=ft.colors.GREEN
                )
                page.snack_bar.open = True
                page.update()
            except Exception as ex:
                show_error(f"Erreur lors de l'enregistrement : {ex}")

    # FilePickers
    file_picker = ft.FilePicker(on_result=on_file_result)
    file_picker.file_type = ft.FilePickerFileType.CUSTOM
    file_picker.allowed_extensions = ["jpg", "jpeg", "png", "pdf"]
    
    save_file_picker = ft.FilePicker(on_result=on_save_result)
    
    page.overlay.append(file_picker)
    page.overlay.append(save_file_picker)

    # Références aux contrôles pour update_preview
    watermark_text = ft.TextField(
        label="Texte du filigrane",
        value="COPIE",
        color="#ffffff",
        border_color="#3b82f6",
        focused_border_color="#60a5fa",
        on_change=update_preview,
        disabled=True,
    )
    
    opacity_label = ft.Text("Opacité (30%)", size=14, color="#ffffff")
    opacity_slider = ft.Slider(
        min=0, max=100, value=30, divisions=100, label="{value}%",
        active_color="#3b82f6", on_change=update_preview, disabled=True
    )
    
    font_size_label = ft.Text("Taille de police (36 px)", size=14, color="#ffffff")
    font_size_slider = ft.Slider(
        min=12, max=72, value=36, divisions=60, label="{value}px",
        active_color="#3b82f6", on_change=update_preview, disabled=True
    )
    
    spacing_label = ft.Text("Espacement (150 px)", size=14, color="#ffffff")
    spacing_slider = ft.Slider(
        min=50, max=300, value=150, divisions=250, label="{value}px",
        active_color="#3b82f6", on_change=update_preview, disabled=True
    )

    save_button = ft.ElevatedButton(
        "Enregistrer l'image",
        icon=ft.icons.SAVE,
        on_click=lambda _: save_file_picker.save_file(
            file_name="image_filigree.jpg",
            allowed_extensions=["jpg", "jpeg", "png"]
        ),
        bgcolor=ft.colors.GREEN_700,
        color="#ffffff",
        disabled=True,
    )

    # Panneau de contrôles (gauche)
    controls_panel = ft.Container(
        content=ft.Column(
            controls=[
                ft.Text("Contrôles", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                watermark_text,
                ft.Column(controls=[opacity_label, opacity_slider], spacing=0),
                ft.Column(controls=[font_size_label, font_size_slider], spacing=0),
                ft.Column(controls=[spacing_label, spacing_slider], spacing=0),
                ft.ElevatedButton(
                    "Sélectionner un fichier",
                    icon=ft.icons.UPLOAD_FILE,
                    on_click=lambda _: file_picker.pick_files(
                        allow_multiple=False,
                        allowed_extensions=["jpg", "jpeg", "png", "pdf"]
                    ),
                    bgcolor="#3b82f6",
                    color="#ffffff",
                ),
                file_info_text,
                export_format_dropdown,
                save_button,
            ],
            spacing=12,
        ),
        width=300,
        bgcolor="#252525", # Fond secondaire: Gris foncé
        padding=16, # Padding interne des panneaux
        border_radius=ft.border_radius.all(8), # Coins arrondis
    )

    # Panneau de prévisualisation (droite)
    preview_panel = ft.Container(
        content=ft.Column(
            controls=[
                ft.Text("Prévisualisation", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                ft.Container(
                    content=preview_image,
                    expand=True,
                    alignment=ft.alignment.center,
                ),
            ],
            spacing=12,
        ),
        expand=True,
        bgcolor="#1a1a1a", # Fond principal: Noir profond
        padding=16, # Padding interne des panneaux
    )

    # Layout principal
    main_layout = ft.Row(
        controls=[
            controls_panel,
            preview_panel,
        ],
        expand=True,
        spacing=0,
    )

    page.add(main_layout)
    page.update()

if __name__ == "__main__":
    ft.app(target=main)
