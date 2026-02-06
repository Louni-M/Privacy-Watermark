import flet as ft
from PIL import Image, ImageDraw, ImageFont
import io
import base64
import os
import sys
import stat
import threading
import traceback
from pdf_processing import (
    load_pdf,
    pdf_page_to_image,
    apply_watermark_to_pdf,  # Raster watermark (for backward compatibility)
    apply_vector_watermark_to_pdf,  # Vector watermark (new, quality-preserving)
    save_watermarked_pdf,
    save_pdf_as_images,
    apply_watermark_to_pil_image,
    generate_pdf_preview,
    apply_secure_raster_watermark_to_pdf
)

# --- Security constants ---
MAX_FILE_SIZE_BYTES = 100 * 1024 * 1024  # 100 MB
MAX_PDF_PAGES = 50
MAX_IMAGE_DIMENSION = 20000  # pixels per side

def get_log_path():
    """Return a secure, platform-appropriate log file path."""
    if sys.platform == "darwin":
        log_dir = os.path.expanduser("~/Library/Logs/PassportFiligrane")
    elif sys.platform == "win32":
        log_dir = os.path.join(os.environ.get("APPDATA", os.path.expanduser("~")), "PassportFiligrane", "Logs")
    else:
        log_dir = os.path.join(os.environ.get("XDG_STATE_HOME", os.path.expanduser("~/.local/state")), "PassportFiligrane")

    os.makedirs(log_dir, mode=0o700, exist_ok=True)
    return os.path.join(log_dir, "error_log.txt")

LOG_PATH = get_log_path()

def sanitize_path_for_log(message: str) -> str:
    """Remove potential file paths from log messages to protect user privacy."""
    home = os.path.expanduser("~")
    return message.replace(home, "~USER")


def generate_preview(image_bytes_io):
    """Genere un thumbnail de l'image (max 800px) pour la previsualisation."""
    img = Image.open(image_bytes_io)
    max_size = 800
    if img.width > max_size or img.height > max_size:
        img.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')
    return img_byte_arr.getvalue()

def get_font(size):
    """Essaye de charger une police systeme, sinon retourne la police par defaut."""
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

def strip_image_metadata(img):
    """Return a clean copy of a PIL Image with all EXIF/metadata stripped."""
    clean = Image.new(img.mode, img.size)
    clean.putdata(list(img.getdata()))
    return clean

def apply_watermark(image_bytes, text, opacity, font_size, spacing, color="Blanc", orientation="Ascendant (↗)"):
    """Applique un filigrane repete en diagonale sur l'image."""
    img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    # Utilisation de la logique partagee de pdf_processing pour la coherence
    out = apply_watermark_to_pil_image(img, text, opacity, font_size, spacing, color=color, orientation=orientation)
    out_rgb = strip_image_metadata(out.convert("RGB"))
    output = io.BytesIO()
    out_rgb.save(output, format="JPEG", quality=90)
    return output.getvalue()

def detect_file_type(file_path):
    """Determine si le fichier est une image ou un PDF."""
    ext = os.path.splitext(file_path)[1].lower()
    if ext in ['.jpg', '.jpeg', '.png']:
        return "image"
    elif ext == '.pdf':
        return "pdf"
    return "unknown"

def validate_file_size(file_path):
    """Check that a file does not exceed the maximum allowed size."""
    size = os.path.getsize(file_path)
    if size > MAX_FILE_SIZE_BYTES:
        size_mb = size / (1024 * 1024)
        raise ValueError(
            f"Fichier trop volumineux ({size_mb:.1f} Mo). "
            f"La limite est de {MAX_FILE_SIZE_BYTES // (1024 * 1024)} Mo."
        )

def validate_image_dimensions(img):
    """Check that an image's dimensions are within safe limits."""
    if img.width > MAX_IMAGE_DIMENSION or img.height > MAX_IMAGE_DIMENSION:
        raise ValueError(
            f"Image trop grande ({img.width}x{img.height} px). "
            f"La limite est de {MAX_IMAGE_DIMENSION}x{MAX_IMAGE_DIMENSION} px."
        )


class PassportFiligraneApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.title = "Passport Filigrane"
        self.page.theme_mode = ft.ThemeMode.DARK
        self.page.padding = 0
        self.page.bgcolor = "#1a1a1a"

        # State
        self.original_image_bytes = None
        self.watermarked_image_bytes = None
        self.pdf_doc = None
        self.current_file_type = None
        self.num_pages = 0
        self.update_timer = None
        self._preview_lock = threading.Lock()

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

        self.opacity_label = ft.Text("Opacite (30%)", size=14, color="#ffffff")
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

        self.color_dropdown = ft.Dropdown(
            label="Couleur du texte", label_style=ft.TextStyle(color="#ffffff", size=14),
            options=[
                ft.dropdown.Option("Blanc", "Blanc"),
                ft.dropdown.Option("Noir", "Noir"),
                ft.dropdown.Option("Gris", "Gris"),
            ],
            value="Blanc", on_change=self.update_preview, disabled=True
        )

        self.orientation_dropdown = ft.Dropdown(
            label="Orientation", label_style=ft.TextStyle(color="#ffffff", size=14),
            options=[
                ft.dropdown.Option("Ascendant (↗)", "Ascendant (↗)"),
                ft.dropdown.Option("Descendant (↘)", "Descendant (↘)"),
            ],
            value="Ascendant (↗)", on_change=self.update_preview, disabled=True
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

        # Mode Securise & DPI selection
        self.secure_mode_switch = ft.Switch(
            label="Mode Securise (Raster)",
            value=False,
            active_color="#3b82f6",
            on_change=self.on_secure_mode_change,
            disabled=True,
            visible=False # Only for PDFs
        )

        self.vector_mode_warning = ft.Container(
            content=ft.Text(
                "Mode vectoriel : le filigrane peut etre supprime avec un editeur PDF. "
                "Activez le Mode Securise pour les documents sensibles.",
                size=11,
                color="#ff9800",
                italic=True,
            ),
            visible=False,
            padding=ft.padding.only(top=4, bottom=4),
        )

        self.dpi_segmented_button = ft.SegmentedButton(
            segments=[
                ft.Segment(value="300", label=ft.Text("300")),
                ft.Segment(value="450", label=ft.Text("450")),
                ft.Segment(value="600", label=ft.Text("600")),
            ],
            selected={"450"},
            on_change=self.update_preview,
            visible=True,
            disabled=True
        )

        self.dpi_container = ft.Column(
            controls=[
                ft.Text("Qualite (DPI)", size=12, color="#aaaaaa"),
                self.dpi_segmented_button
            ],
            spacing=5,
            visible=False
        )

        self.file_info_text = ft.Text("", size=12, color="#aaaaaa", italic=True, visible=False)
        self.preview_image = ft.Image(src_base64="", fit="contain", visible=False)

        # Layout panels
        controls_panel = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text("Controles", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                    self.watermark_text,
                    ft.Column(controls=[self.opacity_label, self.opacity_slider], spacing=0),
                    ft.Column(controls=[self.font_size_label, self.font_size_slider], spacing=0),
                    ft.Column(controls=[self.spacing_label, self.spacing_slider], spacing=0),
                    self.color_dropdown,
                    self.orientation_dropdown,
                    ft.Divider(height=20, color="transparent"),
                    self.secure_mode_switch,
                    self.vector_mode_warning,
                    self.dpi_container,
                    ft.Divider(height=20, color="transparent"),
                    ft.ElevatedButton(
                        "Selectionner un fichier", icon=ft.icons.UPLOAD_FILE,
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
                scroll=ft.ScrollMode.AUTO,
            ),
            width=300, bgcolor="#252525", padding=16, border_radius=ft.border_radius.all(8),
        )

        preview_panel = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text("Previsualisation", size=18, weight=ft.FontWeight.BOLD, color="#ffffff"),
                    ft.Container(content=self.preview_image, expand=True, alignment=ft.alignment.center),
                ],
                spacing=12,
            ),
            expand=True, bgcolor="#1a1a1a", padding=16,
        )

        self.page.add(ft.Row(controls=[controls_panel, preview_panel], expand=True, spacing=0))

    def show_error(self, message: str):
        # Log to secure location, sanitizing file paths
        try:
            sanitized = sanitize_path_for_log(message)
            with open(LOG_PATH, "a") as f:
                f.write(f"\n--- ERROR: {sanitized} ---\n")
                traceback.print_exc(file=f)
            # Restrict permissions to owner-only
            os.chmod(LOG_PATH, stat.S_IRUSR | stat.S_IWUSR)
        except OSError:
            pass  # Logging failure should not crash the app

        self.page.snack_bar = ft.SnackBar(ft.Text(message), bgcolor=ft.colors.ERROR)
        self.page.snack_bar.open = True
        self.page.update()

    def set_controls_disabled(self, disabled: bool):
        self.watermark_text.disabled = disabled
        self.opacity_slider.disabled = disabled
        self.font_size_slider.disabled = disabled
        self.spacing_slider.disabled = disabled
        self.color_dropdown.disabled = disabled
        self.orientation_dropdown.disabled = disabled
        self.save_button.disabled = disabled or self.watermarked_image_bytes is None
        self.secure_mode_switch.disabled = disabled
        self.dpi_segmented_button.disabled = disabled

        if self.current_file_type == "pdf" and self.export_format_dropdown.value == "Images":
            self.save_button.text = "Exporter en images"
        else:
            self.save_button.text = "Enregistrer le fichier"
        self.page.update()

    def _update_vector_warning_visibility(self):
        """Show warning when PDF is loaded in vector (non-secure) mode."""
        is_pdf = self.current_file_type == "pdf"
        is_vector = not self.secure_mode_switch.value
        self.vector_mode_warning.visible = is_pdf and is_vector

    def on_secure_mode_change(self, e):
        # Toggle DPI selection visibility
        self.dpi_container.visible = self.secure_mode_switch.value
        self._update_vector_warning_visibility()
        self.update_preview()
        self.page.update()

    def update_preview(self, e=None):
        self.opacity_label.value = f"Opacite ({int(self.opacity_slider.value)}%)"
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
            with self._preview_lock:
                try:
                    text = self.watermark_text.value
                    opacity = self.opacity_slider.value
                    font_size = int(self.font_size_slider.value)
                    spacing = int(self.spacing_slider.value)
                    color = self.color_dropdown.value
                    orientation = self.orientation_dropdown.value
                    file_type = self.current_file_type

                    if file_type == "image" and self.original_image_bytes:
                        self.watermarked_image_bytes = apply_watermark(self.original_image_bytes, text, opacity, font_size, spacing, color=color, orientation=orientation)
                    elif file_type == "pdf" and self.pdf_doc:
                        self.watermarked_image_bytes = generate_pdf_preview(
                             doc=self.pdf_doc,
                             text=text,
                             opacity=opacity,
                             font_size=font_size,
                             spacing=spacing,
                             color=color,
                             orientation=orientation
                        )

                    if self.watermarked_image_bytes:
                        self.preview_image.src_base64 = base64.b64encode(self.watermarked_image_bytes).decode("utf-8")
                        self.preview_image.visible = True
                        self.save_button.disabled = False
                        self.page.update()
                except Exception as ex:
                    self.show_error(f"Erreur de mise a jour : {ex}")

        self.update_timer = threading.Timer(0.2, do_update)
        self.update_timer.start()

    def on_file_result(self, e: ft.FilePickerResultEvent):
        if not e.files:
            return

        file_path = e.files[0].path
        if not file_path:
            return

        try:
            # Validate file size before loading
            validate_file_size(file_path)

            self.current_file_type = detect_file_type(file_path)

            if self.current_file_type == "image":
                with open(file_path, "rb") as f:
                    content = f.read()
                try:
                    img = Image.open(io.BytesIO(content))
                    img.verify()
                    # Re-open after verify (verify can close the image)
                    img = Image.open(io.BytesIO(content))
                    validate_image_dimensions(img)
                except Exception:
                    self.show_error("Impossible de lire ce fichier image.")
                    return
                self.original_image_bytes = content
                self.pdf_doc = None
                self.file_info_text.value = "Image chargee"
                self.export_format_dropdown.visible = False
                self.secure_mode_switch.visible = False
                self.vector_mode_warning.visible = False
                self.dpi_container.visible = False

            elif self.current_file_type == "pdf":
                self.current_file_type = "pdf"
                self.pdf_doc, self.num_pages = load_pdf(file_path)

                if self.num_pages > MAX_PDF_PAGES:
                    self.show_error(
                        f"PDF trop volumineux ({self.num_pages} pages). "
                        f"La limite est de {MAX_PDF_PAGES} pages."
                    )
                    self.pdf_doc = None
                    self.current_file_type = None
                    self.set_controls_disabled(True)
                    self.page.update()
                    return

                self.export_format_dropdown.visible = True
                self.secure_mode_switch.visible = True
                self._update_vector_warning_visibility()
                self.dpi_container.visible = self.secure_mode_switch.value
                self.file_info_text.value = f"PDF charge : {self.num_pages} page(s)"
            else:
                self.current_file_type = None
                self.pdf_doc = None
                self.export_format_dropdown.visible = False
                self.secure_mode_switch.visible = False
                self.vector_mode_warning.visible = False
                self.dpi_container.visible = False
                self.show_error("Format de fichier non supporte.")
                self.set_controls_disabled(True)
                self.page.update()
                return

            self.file_info_text.visible = True
            self.set_controls_disabled(False)
            self.update_preview()
            self.preview_image.visible = True
            self.page.update()
        except ValueError as ve:
            self.show_error(str(ve))
            self.set_controls_disabled(True)
            self.page.update()
        except Exception as ex:
            self.current_file_type = None
            self.pdf_doc = None
            self.export_format_dropdown.visible = False
            self.secure_mode_switch.visible = False
            self.vector_mode_warning.visible = False
            self.dpi_container.visible = False
            self.show_error(str(ex))
            self.set_controls_disabled(True)
            self.page.update()

    def on_save_result(self, e: ft.FilePickerResultEvent):
        if not e.path:
            return
        try:
            if self.current_file_type == "image":
                with open(e.path, "wb") as f:
                    f.write(self.watermarked_image_bytes)
            elif self.current_file_type == "pdf" and self.pdf_doc:
                if self.secure_mode_switch.value:
                    # Secure raster mode
                    dpi = int(list(self.dpi_segmented_button.selected)[0])
                    doc_to_save = apply_secure_raster_watermark_to_pdf(
                        doc=self.pdf_doc,
                        text=self.watermark_text.value,
                        opacity=self.opacity_slider.value,
                        font_size=int(self.font_size_slider.value),
                        spacing=int(self.spacing_slider.value),
                        color=self.color_dropdown.value,
                        dpi=dpi,
                        orientation=self.orientation_dropdown.value
                    )
                else:
                    # Classic vector mode
                    apply_vector_watermark_to_pdf(
                        doc=self.pdf_doc,
                        text=self.watermark_text.value,
                        opacity=self.opacity_slider.value,
                        font_size=int(self.font_size_slider.value),
                        spacing=int(self.spacing_slider.value),
                        color=self.color_dropdown.value,
                        orientation=self.orientation_dropdown.value
                    )
                    doc_to_save = self.pdf_doc

                save_watermarked_pdf(doc_to_save, e.path)

            self.page.snack_bar = ft.SnackBar(
                ft.Text(f"Fichier enregistre : {os.path.basename(e.path)}"),
                bgcolor=ft.colors.GREEN
            )
            self.page.snack_bar.open = True
            self.page.update()
        except Exception as ex:
            self.show_error(f"Erreur lors de la sauvegarde : {ex}")

    def on_dir_result(self, e: ft.FilePickerResultEvent):
        if e.path and self.current_file_type == "pdf" and self.pdf_doc:
            try:
                if self.secure_mode_switch.value:
                    # Secure raster mode
                    dpi = int(list(self.dpi_segmented_button.selected)[0])
                    doc_to_save = apply_secure_raster_watermark_to_pdf(
                        doc=self.pdf_doc,
                        text=self.watermark_text.value,
                        opacity=self.opacity_slider.value,
                        font_size=int(self.font_size_slider.value),
                        spacing=int(self.spacing_slider.value),
                        color=self.color_dropdown.value,
                        dpi=dpi,
                        orientation=self.orientation_dropdown.value
                    )
                else:
                    # Classic vector mode
                    apply_vector_watermark_to_pdf(
                        doc=self.pdf_doc,
                        text=self.watermark_text.value,
                        opacity=self.opacity_slider.value,
                        font_size=int(self.font_size_slider.value),
                        spacing=int(self.spacing_slider.value),
                        color=self.color_dropdown.value,
                        orientation=self.orientation_dropdown.value
                    )
                    doc_to_save = self.pdf_doc

                save_pdf_as_images(doc_to_save, e.path, "export")
                self.page.snack_bar = ft.SnackBar(
                    ft.Text(f"Images exportees dans : {os.path.basename(e.path)}"),
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
