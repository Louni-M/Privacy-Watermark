import flet as ft
from PIL import Image
import io
import base64

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

def main(page: ft.Page):
    page.title = "Passport Filigrane"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.bgcolor = "#1a1a1a"

    # Zone d'image pour la prévisualisation
    preview_image = ft.Image(
        src="",
        fit="contain",
        visible=False,
    )
    preview_image.src_base64 = ""

    def on_file_result(e: ft.FilePickerResultEvent):
        if e.files:
            file_path = e.files[0].path
            with open(file_path, "rb") as f:
                image_bytes = f.read()
            
            preview_bytes = generate_preview(io.BytesIO(image_bytes))
            import base64
            preview_image.src_base64 = base64.b64encode(preview_bytes).decode("utf-8")
            preview_image.visible = True
            page.update()

    # FilePicker pour la sélection d'image
    file_picker = ft.FilePicker()
    file_picker.on_result = on_file_result
    file_picker.file_type = ft.FilePickerFileType.IMAGE
    page.overlay.append(file_picker)

    # Panneau de contrôles (gauche)
    controls_panel = ft.Container(
        content=ft.Column(
            controls=[
                ft.Text("Contrôles", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                ft.ElevatedButton(
                    content=ft.Text("Sélectionner une image"),
                    icon=ft.Icons.IMAGE,
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
        border_radius=ft.BorderRadius.all(8), # Coins arrondis
    )

    # Panneau de prévisualisation (droite)
    preview_panel = ft.Container(
        content=ft.Column(
            controls=[
                ft.Text("Prévisualisation", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                ft.Container(
                    content=preview_image,
                    expand=True,
                    alignment=ft.Alignment(0, 0),
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
