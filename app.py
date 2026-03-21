"""PassportFiligraneApp - UI and state management for the watermarking application."""

import flet as ft
import base64
import io
import os
import stat
import threading
import traceback

from PIL import Image
from watermark import WatermarkParams, apply_watermark
from constants import (
    MAX_PDF_PAGES,
    EXPORT_FILENAME_PREFIX,
    BG_PRIMARY, BG_SECONDARY,
    ACCENT_PINK, ACCENT_PINK_LIGHT, ACCENT_GREEN, ACCENT_YELLOW, ACCENT_PURPLE, ACCENT_CYAN,
    TEXT_WHITE, TEXT_MUTED, TEXT_WARNING,
)
from utils import (
    get_log_path,
    sanitize_path_for_log,
    detect_file_type,
    validate_file_size,
    validate_image_dimensions,
)

LOG_PATH = get_log_path()


class PassportFiligraneApp:
    def __init__(self, page: ft.Page):
        self.page = page
        self.page.title = "Passport Filigrane"
        self.page.theme_mode = ft.ThemeMode.DARK
        self.page.padding = 0
        self.page.bgcolor = BG_PRIMARY

        # State
        self.original_image_bytes: bytes | None = None
        self.watermarked_image_bytes: bytes | None = None
        self.pdf_doc = None
        self.current_file_type: str | None = None
        self.num_pages: int = 0
        self.current_filename: str = ""
        self.update_timer: threading.Timer | None = None
        self._preview_lock = threading.Lock()

        # Preview animation settings
        self._preview_fade_opacity = 0.3
        self._preview_fade_duration_ms = 300

        self.setup_ui()

    # -------------------------------------------------------------------------
    # UI setup helpers
    # -------------------------------------------------------------------------

    def _create_file_pickers(self) -> None:
        """Create the three FilePicker widgets."""
        self.file_picker = ft.FilePicker(on_result=self.on_file_result)
        self.file_picker.file_type = ft.FilePickerFileType.CUSTOM
        self.file_picker.allowed_extensions = ["jpg", "jpeg", "png", "pdf"]

        self.save_file_picker = ft.FilePicker(on_result=self.on_save_result)
        self.save_dir_picker = ft.FilePicker(on_result=self.on_dir_result)
        self.page.overlay.extend([self.file_picker, self.save_file_picker, self.save_dir_picker])

    def _create_watermark_controls(self) -> None:
        """Create watermark text, opacity, font size, spacing controls."""
        self.watermark_text = ft.TextField(
            label="Watermark text", value="COPY", color=TEXT_WHITE,
            border_color=ACCENT_PINK, focused_border_color=ACCENT_PINK_LIGHT,
            on_change=self.update_preview, disabled=True, max_length=200,
        )

        self.opacity_label = ft.Text("Opacity (30%)", size=14, color=TEXT_WHITE)
        self.opacity_slider = ft.Slider(
            min=0, max=100, value=30, divisions=100, label="{value}%",
            active_color=ACCENT_GREEN, on_change=self.update_preview, disabled=True
        )

        self.font_size_label = ft.Text("Font size (36 px)", size=14, color=TEXT_WHITE)
        self.font_size_slider = ft.Slider(
            min=12, max=72, value=36, divisions=60, label="{value}px",
            active_color=ACCENT_YELLOW, on_change=self.update_preview, disabled=True
        )

        self.spacing_label = ft.Text("Spacing (150 px)", size=14, color=TEXT_WHITE)
        self.spacing_slider = ft.Slider(
            min=50, max=300, value=150, divisions=250, label="{value}px",
            active_color=ACCENT_PURPLE, on_change=self.update_preview, disabled=True
        )

    def _create_mode_controls(self) -> None:
        """Create color, orientation, secure mode, and DPI controls."""
        self.color_dropdown = ft.Dropdown(
            label="Text color", label_style=ft.TextStyle(color=TEXT_WHITE, size=14),
            options=[
                ft.dropdown.Option("White", "White"),
                ft.dropdown.Option("Black", "Black"),
                ft.dropdown.Option("Gray", "Gray"),
            ],
            value="White", on_change=self.update_preview, disabled=True
        )

        self.orientation_dropdown = ft.Dropdown(
            label="Orientation", label_style=ft.TextStyle(color=TEXT_WHITE, size=14),
            options=[
                ft.dropdown.Option("Ascending (↗)", "Ascending (↗)"),
                ft.dropdown.Option("Descending (↘)", "Descending (↘)"),
            ],
            value="Ascending (↗)", on_change=self.update_preview, disabled=True
        )

        self.export_format_dropdown = ft.Dropdown(
            label="Export format", label_style=ft.TextStyle(color=TEXT_WHITE, size=14),
            options=[ft.dropdown.Option("PDF", "PDF"), ft.dropdown.Option("Images (JPG)", "Images")],
            value="PDF", visible=False, on_change=lambda _: self.page.update()
        )

        self.save_button = ft.ElevatedButton(
            "Save file", icon=ft.icons.SAVE,
            on_click=self.on_save_button_click, bgcolor=ft.colors.GREEN_700,
            color=TEXT_WHITE, disabled=True,
        )

        self.secure_mode_switch = ft.Switch(
            label="Secure Mode (Raster)",
            value=False,
            active_color=ACCENT_CYAN,
            on_change=self.on_secure_mode_change,
            disabled=True,
            visible=False,
        )

        self.vector_mode_warning = ft.Container(
            content=ft.Text(
                "Vector mode: the watermark can be removed with a PDF editor. "
                "Enable Secure Mode for sensitive documents.",
                size=11,
                color=TEXT_WARNING,
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
                ft.Text("Quality (DPI)", size=12, color=TEXT_MUTED),
                self.dpi_segmented_button
            ],
            spacing=5,
            visible=False
        )

    def _create_select_file_button(self) -> ft.ElevatedButton:
        """Create the 'Select a file' button used in both empty state and controls panel."""
        return ft.ElevatedButton(
            "Select a file", icon=ft.icons.UPLOAD_FILE,
            on_click=lambda _: self.file_picker.pick_files(
                allow_multiple=False, allowed_extensions=["jpg", "jpeg", "png", "pdf"]
            ),
            bgcolor=ACCENT_PINK, color=TEXT_WHITE,
        )

    def _create_empty_state(self) -> ft.Container:
        return ft.Container(
            content=ft.Column(
                controls=[
                    ft.Icon(ft.icons.UPLOAD_FILE, size=64, color=ACCENT_PINK_LIGHT),
                    ft.Text("No file selected", size=18, color=TEXT_WHITE, weight=ft.FontWeight.BOLD),
                    ft.Text("Click below or drag a file here", size=14, color=TEXT_MUTED),
                    self._create_select_file_button(),
                ],
                alignment=ft.alignment.center,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=12,
            ),
            expand=True, alignment=ft.alignment.center,
        )

    def _create_loading_indicator(self) -> ft.Container:
        """Create the loading spinner shown while preview is being generated."""
        return ft.Container(
            content=ft.Column(
                controls=[
                    ft.ProgressRing(color=ACCENT_PINK, width=40, height=40),
                    ft.Text("Loading preview...", size=14, color=TEXT_MUTED),
                ],
                alignment=ft.alignment.center,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                spacing=8,
            ),
            expand=True, alignment=ft.alignment.center, visible=False,
        )

    def _set_preview_visibility(self, *, empty: bool = False, loading: bool = False, ready: bool = False) -> None:
        """Set preview area visibility state for empty, loading, or ready states."""
        self.empty_state_container.visible = empty
        self.loading_indicator.visible = loading
        self.preview_image.visible = ready

    def _create_export_controls(self) -> None:
        """Create file info display and preview image."""
        self.file_info_text = ft.Text("", size=12, color=TEXT_MUTED, italic=True, visible=False)
        self.preview_image = ft.Image(src_base64="", fit="contain", visible=False)
        self.empty_state_container = self._create_empty_state()
        self.loading_indicator = self._create_loading_indicator()

    def _build_layout(self) -> None:
        """Assemble all controls into the two-panel layout."""
        controls_panel = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text("Controls", size=18, weight=ft.FontWeight.BOLD, color=TEXT_WHITE),
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
                    self._create_select_file_button(),
                    self.file_info_text,
                    self.export_format_dropdown,
                    self.save_button,
                ],
                spacing=12,
                scroll=ft.ScrollMode.AUTO,
            ),
            width=300, bgcolor=BG_SECONDARY, padding=16, border_radius=ft.border_radius.all(8),
        )

        preview_panel = ft.Container(
            content=ft.Column(
                controls=[
                    ft.Text("Preview", size=18, weight=ft.FontWeight.BOLD, color=TEXT_WHITE),
                    ft.Stack(
                        controls=[
                            self.empty_state_container,
                            self.loading_indicator,
                            self.preview_image,
                        ],
                        expand=True,
                    ),
                ],
                spacing=12,
                expand=True,
            ),
            expand=True, bgcolor=BG_PRIMARY, padding=16,
        )

        self.page.add(ft.Row(controls=[controls_panel, preview_panel], expand=True, spacing=0))

    def setup_ui(self) -> None:
        """Compose all UI elements. Dispatches to focused helper methods."""
        self._create_file_pickers()
        self._create_watermark_controls()
        self._create_mode_controls()
        self._create_export_controls()
        self._build_layout()

    # -------------------------------------------------------------------------
    # Error / success feedback
    # -------------------------------------------------------------------------

    def _show_error(self, message: str) -> None:
        """Log an error to disk and display a snackbar notification."""
        try:
            sanitized = sanitize_path_for_log(message)
            with open(LOG_PATH, "a") as f:
                f.write(f"\n--- ERROR: {sanitized} ---\n")
                traceback.print_exc(file=f)
            os.chmod(LOG_PATH, stat.S_IRUSR | stat.S_IWUSR)
        except OSError:
            pass

        self.page.snack_bar = ft.SnackBar(ft.Text(message), bgcolor=ft.colors.ERROR)
        self.page.snack_bar.open = True
        self.page.update()

    def _show_success(self, message: str) -> None:
        self.page.snack_bar = ft.SnackBar(ft.Text(message), bgcolor=ft.colors.GREEN)
        self.page.snack_bar.open = True
        self.page.update()

    # -------------------------------------------------------------------------
    # Control helpers
    # -------------------------------------------------------------------------

    def _reset_pdf_controls(self) -> None:
        """Hide all PDF-only controls. Used when unloading a PDF or on error."""
        self.secure_mode_switch.visible = False
        self.vector_mode_warning.visible = False
        self.dpi_container.visible = False

    def _update_save_button_text(self) -> None:
        if self.current_file_type == "pdf" and (self.export_format_dropdown.value or "").startswith("Images"):
            self.save_button.text = "Export as images"
        else:
            self.save_button.text = "Save file"

    def _get_watermark_params(self) -> WatermarkParams:
        return WatermarkParams(
            text=self.watermark_text.value,
            opacity=self.opacity_slider.value,
            font_size=int(self.font_size_slider.value),
            spacing=int(self.spacing_slider.value),
            color=self.color_dropdown.value,
            orientation=self.orientation_dropdown.value,
        )

    def _apply_watermark_to_pdf(self):
        from pdf_processing import (
            apply_vector_watermark_to_pdf,
            apply_secure_raster_watermark_to_pdf,
        )
        params = self._get_watermark_params()
        if self.secure_mode_switch.value:
            dpi = int(list(self.dpi_segmented_button.selected)[0])
            return apply_secure_raster_watermark_to_pdf(self.pdf_doc, params, dpi=dpi)
        else:
            apply_vector_watermark_to_pdf(self.pdf_doc, params)
            return self.pdf_doc

    def set_controls_disabled(self, disabled: bool) -> None:
        self.watermark_text.disabled = disabled
        self.opacity_slider.disabled = disabled
        self.font_size_slider.disabled = disabled
        self.spacing_slider.disabled = disabled
        self.color_dropdown.disabled = disabled
        self.orientation_dropdown.disabled = disabled
        self.save_button.disabled = disabled or self.watermarked_image_bytes is None
        self.secure_mode_switch.disabled = disabled
        self.dpi_segmented_button.disabled = disabled
        self._update_save_button_text()
        self.page.update()

    def update_export_options(self, file_type: str) -> None:
        """Update export dropdown options based on file type."""
        if file_type == "image":
            self.export_format_dropdown.options = [
                ft.dropdown.Option("JPG", "JPG"),
                ft.dropdown.Option("PNG", "PNG"),
                ft.dropdown.Option("PDF", "PDF"),
            ]
            self.export_format_dropdown.value = "JPG"
            self.export_format_dropdown.visible = True
        elif file_type == "pdf":
            self.export_format_dropdown.options = [
                ft.dropdown.Option("PDF", "PDF"),
                ft.dropdown.Option("Images (JPG)", "Images (JPG)"),
                ft.dropdown.Option("Images (PNG)", "Images (PNG)"),
            ]
            self.export_format_dropdown.value = "PDF"
            self.export_format_dropdown.visible = True
        else:
            self.export_format_dropdown.visible = False

        self.page.update()

    def _update_vector_warning_visibility(self) -> None:
        is_pdf = self.current_file_type == "pdf"
        is_vector = not self.secure_mode_switch.value
        self.vector_mode_warning.visible = is_pdf and is_vector

    # -------------------------------------------------------------------------
    # Event handlers
    # -------------------------------------------------------------------------

    def on_secure_mode_change(self, e) -> None:
        self.dpi_container.visible = self.secure_mode_switch.value
        self._update_vector_warning_visibility()
        self.update_preview()
        self.page.update()

    def update_preview(self, e=None) -> None:
        self.opacity_label.value = f"Opacity ({int(self.opacity_slider.value)}%)"
        self.font_size_label.value = f"Font size ({int(self.font_size_slider.value)} px)"
        self.spacing_label.value = f"Spacing ({int(self.spacing_slider.value)} px)"
        self._update_save_button_text()
        self.page.update()

        if self.current_file_type is None:
            self._set_preview_visibility(empty=True)
            self.page.update()
            return

        if self.update_timer:
            self.update_timer.cancel()

        def do_update():
            from pdf_processing import generate_pdf_preview

            with self._preview_lock:
                try:
                    params = self._get_watermark_params()
                    file_type = self.current_file_type

                    if file_type == "image" and self.original_image_bytes:
                        fmt = self.export_format_dropdown.value if self.export_format_dropdown.value in ["JPG", "PNG"] else "JPG"
                        self.watermarked_image_bytes = apply_watermark(
                            self.original_image_bytes, params, output_format=fmt
                        )
                    elif file_type == "pdf" and self.pdf_doc:
                        self.watermarked_image_bytes = generate_pdf_preview(self.pdf_doc, params)

                    if self.watermarked_image_bytes:
                        self.preview_image.src_base64 = base64.b64encode(self.watermarked_image_bytes).decode("utf-8")
                        self._set_preview_visibility(ready=True)
                        self.preview_image.visible = True
                        self.save_button.disabled = False
                        self.page.update()
                except Exception as ex:
                    self._show_error(f"Preview update error: {ex}")

        self.update_timer = threading.Timer(0.2, do_update)
        self.update_timer.start()

    def _load_image(self, file_path: str) -> None:
        """Load and validate an image file into state."""
        with open(file_path, "rb") as f:
            content = f.read()
        try:
            img = Image.open(io.BytesIO(content))
            img.verify()
            img = Image.open(io.BytesIO(content))
            validate_image_dimensions(img)
        except Exception:
            self._show_error("Unable to read this image file.")
            return
        self.original_image_bytes = content
        self.pdf_doc = None
        self.file_info_text.value = "Image loaded"
        self.update_export_options("image")
        self._reset_pdf_controls()

    def _load_pdf(self, file_path: str) -> None:
        """Load and validate a PDF file into state. Closes existing pdf_doc."""
        # Close existing document before opening new one (fixes document leak)
        if self.pdf_doc is not None:
            self.pdf_doc.close()
            self.pdf_doc = None

        from pdf_processing import load_pdf

        self.pdf_doc, self.num_pages = load_pdf(file_path)

        if self.num_pages > MAX_PDF_PAGES:
            self._show_error(
                f"PDF too large ({self.num_pages} pages). "
                f"Maximum allowed is {MAX_PDF_PAGES} pages."
            )
            self.pdf_doc.close()
            self.pdf_doc = None
            self.current_file_type = None
            self.set_controls_disabled(True)
            self.page.update()
            return

        self.dpi_container.visible = self.secure_mode_switch.value
        self.secure_mode_switch.visible = True
        self.file_info_text.value = f"PDF loaded: {self.num_pages} page(s)"
        self.update_export_options("pdf")

    def _finalize_file_load(self) -> None:
        """Common finalization after a successful file load."""
        self.file_info_text.visible = True
        self._set_preview_visibility(loading=True)
        self.set_controls_disabled(False)
        self.update_preview()

    def on_file_result(self, e: ft.FilePickerResultEvent) -> None:
        if not e.files:
            return

        file_path = e.files[0].path
        if not file_path:
            return

        self.current_filename = os.path.basename(file_path)

        try:
            validate_file_size(file_path)
            self.current_file_type = detect_file_type(file_path)

            if self.current_file_type == "image":
                self._load_image(file_path)
            elif self.current_file_type == "pdf":
                self._load_pdf(file_path)
            else:
                self.current_file_type = None
                self.pdf_doc = None
                self.update_export_options("unknown")
                self._reset_pdf_controls()
                self._show_error("Unsupported file format.")
                self.set_controls_disabled(True)
                self.page.update()
                return

            self._finalize_file_load()
        except ValueError as ve:
            self._show_error(str(ve))
            self.set_controls_disabled(True)
            self.page.update()
        except Exception as ex:
            self.current_file_type = None
            self.pdf_doc = None
            self.update_export_options("unknown")
            self._reset_pdf_controls()
            self._show_error(str(ex))
            self.set_controls_disabled(True)
            self.page.update()

    def on_save_result(self, e: ft.FilePickerResultEvent) -> None:
        from pdf_processing import save_watermarked_pdf

        if not e.path:
            return
        try:
            if self.current_file_type == "image":
                if self.export_format_dropdown.value == "PDF":
                    from pdf_processing import save_image_as_pdf
                    save_image_as_pdf(self.watermarked_image_bytes, e.path)
                else:
                    with open(e.path, "wb") as f:
                        f.write(self.watermarked_image_bytes)
            elif self.current_file_type == "pdf" and self.pdf_doc:
                save_watermarked_pdf(self._apply_watermark_to_pdf(), e.path)

            self._show_success(f"File saved: {os.path.basename(e.path)}")
        except Exception as ex:
            self._show_error(f"Error while saving: {ex}")

    def on_dir_result(self, e: ft.FilePickerResultEvent) -> None:
        from pdf_processing import save_pdf_as_images

        if e.path and self.current_file_type == "pdf" and self.pdf_doc:
            try:
                doc_to_save = self._apply_watermark_to_pdf()
                fmt = self.export_format_dropdown.value
                img_fmt = "PNG" if "PNG" in fmt else "JPEG"
                base_name = os.path.splitext(self.current_filename)[0] if self.current_filename else "export"
                ext = "png" if img_fmt == "PNG" else "jpg"
                save_pdf_as_images(doc_to_save, e.path, base_name, img_format=img_fmt)

                if self.num_pages > 1:
                    success_msg = f"'{base_name}_page_001.{ext}' and {self.num_pages-1} more exported to: {os.path.basename(e.path)}"
                else:
                    success_msg = f"'{base_name}_page_001.{ext}' exported to: {os.path.basename(e.path)}"
                self._show_success(success_msg)
            except Exception as ex:
                self._show_error(f"Error while exporting images: {ex}")

    def on_save_button_click(self, e) -> None:
        fmt = self.export_format_dropdown.value
        if self.current_file_type == "pdf":
            if fmt == "Images (JPG)" or fmt == "Images (PNG)":
                self.save_dir_picker.get_directory_path()
            else:
                self.save_file_picker.save_file(
                    file_name=f"{EXPORT_FILENAME_PREFIX}.pdf",
                    allowed_extensions=["pdf"]
                )
        elif self.current_file_type == "image":
            if fmt == "PNG":
                self.save_file_picker.save_file(
                    file_name=f"{EXPORT_FILENAME_PREFIX}.png",
                    allowed_extensions=["png"]
                )
            elif fmt == "PDF":
                self.save_file_picker.save_file(
                    file_name=f"{EXPORT_FILENAME_PREFIX}.pdf",
                    allowed_extensions=["pdf"]
                )
            else:
                self.save_file_picker.save_file(
                    file_name=f"{EXPORT_FILENAME_PREFIX}.jpg",
                    allowed_extensions=["jpg", "jpeg"]
                )
        else:
            self.save_file_picker.save_file(
                file_name=f"{EXPORT_FILENAME_PREFIX}.pdf",
                allowed_extensions=["pdf"]
            )
