import flet as ft
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import os

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

def main(page: ft.Page):
    page.title = "Passport Filigrane"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#1a1a1a"

    # Zone d'image pour la prévisualisation
    preview_image = ft.Image(
        src_base64="",
        fit="contain",
        visible=False,
    )

    def on_file_result(e: ft.FilePickerResultEvent):
        if e.files:
            file_path = e.files[0].path
            if not file_path:
                return
                
            try:
                with open(file_path, "rb") as f:
                    image_bytes = f.read()
                
                preview_bytes = generate_preview(io.BytesIO(image_bytes))
                preview_image.src_base64 = base64.b64encode(preview_bytes).decode("utf-8")
                preview_image.visible = True
                page.update()
            except PermissionError:
                page.snack_bar = ft.SnackBar(
                    ft.Text("Erreur de permission : Impossible d'accéder au fichier (vérifiez les accès macOS ou essayez un dossier local)"),
                    bgcolor=ft.colors.ERROR
                )
                page.snack_bar.open = True
                page.update()
            except Exception as ex:
                page.snack_bar = ft.SnackBar(
                    ft.Text(f"Erreur lors du chargement de l'image : {ex}"),
                    bgcolor=ft.colors.ERROR
                )
                page.snack_bar.open = True
                page.update()
        else:
            print("Selection cancelled")

    # FilePicker pour la sélection d'image
    file_picker = ft.FilePicker(on_result=on_file_result)
    file_picker.file_type = ft.FilePickerFileType.IMAGE
    page.overlay.append(file_picker)

    # Panneau de contrôles (gauche)
    controls_panel = ft.Container(
        content=ft.Column(
            controls=[
                ft.Text("Contrôles", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                ft.TextField(
                    label="Texte du filigrane",
                    value="COPIE",
                    color="#ffffff",
                    border_color="#3b82f6",
                    focused_border_color="#60a5fa",
                ),
                ft.Column(
                    controls=[
                        ft.Text("Opacité (30%)", size=14, color="#ffffff"),
                        ft.Slider(
                            min=0,
                            max=100,
                            value=30,
                            divisions=100,
                            label="{value}%",
                            active_color="#3b82f6",
                            on_change=lambda e: print(f"Opacity changed: {e.control.value}") # Placeholder
                        ),
                    ],
                    spacing=0,
                ),
                ft.Column(
                    controls=[
                        ft.Text("Taille de police (36 px)", size=14, color="#ffffff"),
                        ft.Slider(
                            min=12,
                            max=72,
                            value=36,
                            divisions=60,
                            label="{value}px",
                            active_color="#3b82f6",
                            on_change=lambda e: print(f"Font size changed: {e.control.value}") # Placeholder
                        ),
                    ],
                    spacing=0,
                ),
                ft.Column(
                    controls=[
                        ft.Text("Espacement (150 px)", size=14, color="#ffffff"),
                        ft.Slider(
                            min=50,
                            max=300,
                            value=150,
                            divisions=250,
                            label="{value}px",
                            active_color="#3b82f6",
                            on_change=lambda e: print(f"Spacing changed: {e.control.value}") # Placeholder
                        ),
                    ],
                    spacing=0,
                ),
                ft.ElevatedButton(
                    "Sélectionner une image",
                    icon=ft.icons.IMAGE,
                    on_click=lambda _: file_picker.pick_files(
                        allow_multiple=False,
                        allowed_extensions=["jpg", "jpeg", "png"]
                    ),
                    bgcolor="#3b82f6",
                    color="#ffffff",
                ),
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
