import flet as ft
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import os
import threading
from pdf_processing import (
    load_pdf, 
    pdf_page_to_image, 
    apply_watermark_to_pdf, 
    save_watermarked_pdf, 
    save_pdf_as_images,
    apply_watermark_to_pil_image
)

def generate_preview(image_bytes_io):
    """Génère un thumbnail de l'image (max 800px) pour la prévisualisation."""
    img = Image.open(image_bytes_io)
    max_size = 800
    if img.width > max_size or img.height > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
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
    # Utilisation de la logique partagée de pdf_processing pour la cohérence
    out = apply_watermark_to_pil_image(img, text, opacity, font_size, spacing)
    output = io.BytesIO()
    out.convert("RGB").save(output, format="JPEG", quality=90)
    return output.getvalue()

def detect_file_type(file_path):
    """Détermine si le fichier est une image ou un PDF."""
    ext = os.path.splitext(file_path)[1].lower()
    if ext in ['.jpg', '.jpeg', '.png']:
        return "image"
    elif ext == '.pdf':
        return "pdf"
    return "unknown"

class PassportFiligraneApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.title = "Passport Filigrane"
        self.page.theme_mode = ft.ThemeMode.DARK
        self.page.padding = 0
        self.page.bgcolor = "#1a1a1a"

        # État
        self.original_image_bytes = None
        self.watermarked_image_bytes = None
        self.pdf_doc = None
        self.current_file_type = None
        self.num_pages = 0
        self.update_timer = None

        self.setup_ui()

    def setup_ui(self):
        # File Pickers
        self.file_picker = ft.FilePicker(on_result=self.on_file_result)
        self.file_picker.file_type = ft.FilePickerFileType.CUSTOM
        self.file_picker.allowed_extensions = ["jpg", "jpeg", "png", "pdf"]
        
        self.save_file_picker = ft.FilePicker(on_result=self.on_save_result)
        self.save_dir_picker = ft.FilePicker(on_result=self.on_dir_result)
        self.page.overlay.extend([self.file_picker, self.save_file_picker, self.save_dir_picker])

        # Controls
        self.watermark_text = ft.TextField(
            label="Texte du filigrane", value="COPIE", color="#ffffff",
            border_color="#3b82f6", focused_border_color="#60a5fa",
            on_change=self.update_preview, disabled=True,
        )

        self.opacity_label = ft.Text("Opacité (30%)", size=14, color="#ffffff")
        self.opacity_slider = ft.Slider(
            min=0, max=100, value=30, divisions=100, label="{value}%",
            active_color="#3b82f6", on_change=self.update_preview, disabled=True
        )

        self.font_size_label = ft.Text("Taille de police (36 px)", size=14, color="#ffffff")
        self.font_size_slider = ft.Slider(
            min=12, max=72, value=36, divisions=60, label="{value}px",
            active_color="#3b82f6", on_change=self.update_preview, disabled=True
        )

        self.spacing_label = ft.Text("Espacement (150 px)", size=14, color="#ffffff")
        self.spacing_slider = ft.Slider(
            min=50, max=300, value=150, divisions=250, label="{value}px",
            active_color="#3b82f6", on_change=self.update_preview, disabled=True
        )

        self.export_format_dropdown = ft.Dropdown(
            label="Format d'export", label_style=ft.TextStyle(color="#ffffff", size=14),
            options=[ft.dropdown.Option("PDF", "PDF"), ft.dropdown.Option("Images (JPG)", "Images")],
            value="PDF", visible=False, on_change=lambda _: self.page.update()
        )

        self.save_button = ft.ElevatedButton(
            "Enregistrer le fichier", icon=ft.icons.SAVE,
            on_click=self.on_save_button_click, bgcolor=ft.colors.GREEN_700,
            color="#ffffff", disabled=True,
        )

        self.file_info_text = ft.Text("", size=12, color="#aaaaaa", italic=True, visible=False)
        self.preview_image = ft.Image(src_base64="", fit="contain", visible=False)

        # Layout panels
        controls_panel = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text("Contrôles", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                    self.watermark_text,
                    ft.Column(controls=[self.opacity_label, self.opacity_slider], spacing=0),
                    ft.Column(controls=[self.font_size_label, self.font_size_slider], spacing=0),
                    ft.Column(controls=[self.spacing_label, self.spacing_slider], spacing=0),
                    ft.ElevatedButton(
                        "Sélectionner un fichier", icon=ft.icons.UPLOAD_FILE,
                        on_click=lambda _: self.file_picker.pick_files(
                            allow_multiple=False, allowed_extensions=["jpg", "jpeg", "png", "pdf"]
                        ),
                        bgcolor="#3b82f6", color="#ffffff",
                    ),
                    self.file_info_text,
                    self.export_format_dropdown,
                    self.save_button,
                ],
                spacing=12,
            ),
            width=300, bgcolor="#252525", padding=16, border_radius=ft.border_radius.all(8),
        )

        preview_panel = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text("Prévisualisation", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                    ft.Container(content=self.preview_image, expand=True, alignment=ft.alignment.center),
                ],
                spacing=12,
            ),
            expand=True, bgcolor="#1a1a1a", padding=16,
        )

        self.page.add(ft.Row(controls=[controls_panel, preview_panel], expand=True, spacing=0))

    def show_error(self, message: str):
        self.page.snack_bar = ft.SnackBar(ft.Text(message), bgcolor=ft.colors.ERROR)
        self.page.snack_bar.open = True
        self.page.update()

    def set_controls_disabled(self, disabled: bool):
        self.watermark_text.disabled = disabled
        self.opacity_slider.disabled = disabled
        self.font_size_slider.disabled = disabled
        self.spacing_slider.disabled = disabled
        self.save_button.disabled = disabled or self.watermarked_image_bytes is None
        
        if self.current_file_type == "pdf" and self.export_format_dropdown.value == "Images":
            self.save_button.text = "Exporter en images"
        else:
            self.save_button.text = "Enregistrer le fichier"
        self.page.update()

    def update_preview(self, e=None):
        self.opacity_label.value = f"Opacité ({int(self.opacity_slider.value)}%)"
        self.font_size_label.value = f"Taille de police ({int(self.font_size_slider.value)} px)"
        self.spacing_label.value = f"Espacement ({int(self.spacing_slider.value)} px)"
        
        if self.current_file_type == "pdf" and self.export_format_dropdown.value == "Images":
            self.save_button.text = "Exporter en images"
        else:
            self.save_button.text = "Enregistrer le fichier"
        self.page.update()

        if self.current_file_type is None:
            return

        if self.update_timer:
            self.update_timer.cancel()

        def do_update():
            try:
                text = self.watermark_text.value
                opacity = self.opacity_slider.value
                font_size = int(self.font_size_slider.value)
                spacing = int(self.spacing_slider.value)
                
                if self.current_file_type == "image":
                    self.watermarked_image_bytes = apply_watermark(self.original_image_bytes, text, opacity, font_size, spacing)
                elif self.current_file_type == "pdf" and self.pdf_doc:
                    first_page_img = pdf_page_to_image(self.pdf_doc, 0)
                    watermarked_img = apply_watermark_to_pil_image(first_page_img, text, opacity, font_size, spacing)
                    buffer = io.BytesIO()
                    watermarked_img.convert("RGB").save(buffer, format="JPEG", quality=90)
                    self.watermarked_image_bytes = buffer.getvalue()
                
                self.preview_image.src_base64 = base64.b64encode(self.watermarked_image_bytes).decode("utf-8")
                self.preview_image.visible = True
                self.save_button.disabled = False
                self.page.update()
            except Exception as ex:
                self.show_error(f"Erreur de mise à jour : {ex}")

        self.update_timer = threading.Timer(0.2, do_update)
        self.update_timer.start()

    def on_file_result(self, e: ft.FilePickerResultEvent):
        if not e.files:
            return
            
        file_path = e.files[0].path
        if not file_path:
            return

        try:
            self.current_file_type = detect_file_type(file_path)
            
            if self.current_file_type == "image":
                with open(file_path, "rb") as f:
                    content = f.read()
                try:
                    Image.open(io.BytesIO(content)).verify()
                except Exception:
                    self.show_error("Impossible de lire ce fichier image.")
                    return
                self.original_image_bytes = content
                self.pdf_doc = None
                self.file_info_text.value = "Image chargée"
                self.export_format_dropdown.visible = False
                
            elif self.current_file_type == "pdf":
                try:
                    self.pdf_doc, self.num_pages = load_pdf(file_path)
                except Exception as ex:
                    self.show_error(str(ex))
                    return
                self.original_image_bytes = None
                self.file_info_text.value = f"PDF chargé ({self.num_pages} pages)"
                self.export_format_dropdown.visible = True
            else:
                self.show_error("Type de fichier non supporté.")
                return

            self.file_info_text.visible = True
            self.set_controls_disabled(False)
            self.update_preview()
            self.preview_image.visible = True
            self.page.update()
        except Exception as ex:
            self.show_error(f"Erreur lors du chargement : {ex}")

    def on_save_result(self, e: ft.FilePickerResultEvent):
        if not e.path:
            return
        try:
            if self.current_file_type == "image":
                with open(e.path, "wb") as f:
                    f.write(self.watermarked_image_bytes)
            elif self.current_file_type == "pdf" and self.pdf_doc:
                params = {
                    "text": self.watermark_text.value,
                    "opacity": self.opacity_slider.value,
                    "font_size": int(self.font_size_slider.value),
                    "spacing": int(self.spacing_slider.value)
                }
                apply_watermark_to_pdf(self.pdf_doc, params)
                save_watermarked_pdf(self.pdf_doc, e.path)
                
            self.page.snack_bar = ft.SnackBar(
                ft.Text(f"Fichier enregistré : {os.path.basename(e.path)}"),
                bgcolor=ft.colors.GREEN
            )
            self.page.snack_bar.open = True
            self.page.update()
        except Exception as ex:
            self.show_error(f"Erreur lors de la sauvegarde : {ex}")

    def on_dir_result(self, e: ft.FilePickerResultEvent):
        if e.path and self.current_file_type == "pdf" and self.pdf_doc:
            try:
                params = {
                    "text": self.watermark_text.value,
                    "opacity": self.opacity_slider.value,
                    "font_size": int(self.font_size_slider.value),
                    "spacing": int(self.spacing_slider.value)
                }
                apply_watermark_to_pdf(self.pdf_doc, params)
                save_pdf_as_images(self.pdf_doc, e.path, "export")
                self.page.snack_bar = ft.SnackBar(
                    ft.Text(f"Images exportées dans : {os.path.basename(e.path)}"),
                    bgcolor=ft.colors.GREEN
                )
                self.page.snack_bar.open = True
                self.page.update()
            except Exception as ex:
                self.show_error(f"Erreur lors de l'export images : {ex}")

    def on_save_button_click(self, e):
        if self.current_file_type == "pdf" and self.export_format_dropdown.value == "Images":
            self.save_dir_picker.get_directory_path()
        else:
            default_ext = "jpg" if self.current_file_type == "image" else "pdf"
            allowed = ["jpg", "jpeg", "png"] if self.current_file_type == "image" else ["pdf"]
            self.save_file_picker.save_file(
                file_name=f"export_filigree.{default_ext}",
                allowed_extensions=allowed
            )

def main(page: ft.Page):
    PassportFiligraneApp(page)

if __name__ == "__main__":
    ft.app(target=main)
