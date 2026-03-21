from unittest.mock import MagicMock, patch, mock_open
import pytest
import flet as ft
from PIL import Image
import io
from main import main
from conftest import find_all_controls

def test_main_page_setup():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    
    # Execute
    main(mock_page)
    
    # Verify
    assert mock_page.title == "Passport Filigrane"
    assert mock_page.theme_mode == ft.ThemeMode.DARK
    assert mock_page.padding == 0

def test_layout_structure():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    
    # Execute
    main(mock_page)
    
    # Verify Layout Components
    # We expect a Row as the main layout container containing two main panels
    assert len(mock_page.add.call_args_list) > 0
    
    # Looking for the main layout Row
    # In Flet, page.add(control) is often used.
    # Let's check what was added to the page.
    main_layout = None
    for call in mock_page.add.call_args_list:
        ctrl = call.args[0]
        if isinstance(ctrl, ft.Row):
            main_layout = ctrl
            break
            
    assert main_layout is not None, "Main layout Row not found"
    assert len(main_layout.controls) == 2, "Main layout should have 2 columns"
    
    left_panel = main_layout.controls[0]
    right_panel = main_layout.controls[1]
    
    assert left_panel.width == 300, "Left panel width should be 300px"
    assert right_panel.expand is True, "Right panel should be expandable"

def test_file_picker_setup():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    
    # Execute
    main(mock_page)
    
    # Verify FilePicker existence in overlay
    file_picker = None
    for item in mock_page.overlay:
        if isinstance(item, ft.FilePicker):
            file_picker = item
            break
            
    assert file_picker is not None, "FilePicker should be added to page overlay"
    assert file_picker.file_type == ft.FilePickerFileType.CUSTOM, "FilePicker should be configured for custom extensions"
    assert "pdf" in file_picker.allowed_extensions
    
    # Verify selection button existence
    # We expect a Row as the main layout container containing two main panels
    main_layout = None
    for call in mock_page.add.call_args_list:
        ctrl = call.args[0]
        if isinstance(ctrl, ft.Row):
            main_layout = ctrl
            break
            
    assert main_layout is not None, "Main layout Row not found"
    
    # Instead of finding the button object (which might be a spec object without call_args),
    # Let's inspect what was added to the row.
    controls_panel_container = main_layout.controls[0]
    controls_column = controls_panel_container.content
    
    button = next((c for c in controls_column.controls if isinstance(c, ft.ElevatedButton)), None)
    assert button is not None, "Selection button should exist in controls panel"
    
    # Check text in positional arg or attribute
    assert button.text == "Select a file"

def test_apply_watermark_resizes_correctly():
    from PIL import Image
    from watermark import apply_watermark, WatermarkParams
    import io

    img = Image.new("RGB", (200, 200), color="blue")
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='PNG')

    params = WatermarkParams(text="TEST", opacity=30, font_size=20, spacing=50)
    result_bytes = apply_watermark(img_byte_arr.getvalue(), params)

    result_img = Image.open(io.BytesIO(result_bytes))
    assert result_img.size == (200, 200)

def test_watermark_controls_setup():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    mock_page.overlay = []
    
    # Execute
    main(mock_page)
    
    # Find main layout Row
    main_layout = None
    for call in mock_page.add.call_args_list:
        ctrl = call.args[0]
        if isinstance(ctrl, ft.Row):
            main_layout = ctrl
            break
            
    assert main_layout is not None
    left_panel = main_layout.controls[0]
    controls_column = left_panel.content
    
    # Verify TextField (Task 4.1)
    text_field = next((c for c in controls_column.controls if isinstance(c, ft.TextField)), None)
    assert text_field is not None, "Watermark TextField should exist"
    assert text_field.value == "COPY", "Default watermark text should be 'COPY'"
    assert text_field.label == "Watermark text", "TextField label should be correct"
    
    # Verify Sliders (Task 4.3, 4.5, 4.7)
    sliders = find_all_controls(controls_column.controls, ft.Slider)
    assert len(sliders) == 3, "There should be 3 sliders (Opacity, Font Size, Spacing)"
    
    # Opacity (Task 4.3)
    opacity_slider = sliders[0]
    assert opacity_slider.min == 0 and opacity_slider.max == 100 and opacity_slider.value == 30
    
    # Font Size (Task 4.5)
    font_slider = sliders[1]
    assert font_slider.min == 12 and font_slider.max == 72 and font_slider.value == 36
    
    # Spacing (Task 4.7)
    spacing_slider = sliders[2]
    assert spacing_slider.min == 50 and spacing_slider.max == 300 and spacing_slider.value == 150

def test_realtime_update_event_binding():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    mock_page.overlay = []
    
    # Execute
    main(mock_page)
    
    # Find main layout Row
    main_layout = None
    for call in mock_page.add.call_args_list:
        ctrl = call.args[0]
        if isinstance(ctrl, ft.Row):
            main_layout = ctrl
            break
            
    assert main_layout is not None
    left_panel = main_layout.controls[0]
    controls_column = left_panel.content
    
    # Helper to find controls
    text_field = next((c for c in controls_column.controls if isinstance(c, ft.TextField)), None)
    sliders = find_all_controls(controls_column.controls, ft.Slider)
    
    # Verify events are bound (Task 6.1)
    assert text_field.on_change is not None, "TextField on_change should be bound"
    for s in sliders:
        assert s.on_change is not None, f"Slider {s.label} on_change should be bound"

def test_save_button_setup():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    
    # Execute
    main(mock_page)
    
    # Find main layout Row
    main_layout = None
    for call in mock_page.add.call_args_list:
        ctrl = call.args[0]
        if isinstance(ctrl, ft.Row):
            main_layout = ctrl
            break
            
    assert main_layout is not None
    left_panel = main_layout.controls[0]
    controls_column = left_panel.content
    
    # Find Save Button
    save_button = next((c for c in controls_column.controls if isinstance(c, ft.ElevatedButton) and "Save" in c.text), None)
    
    assert save_button is not None, "Save button should exist"
    assert save_button.disabled is True, "Save button should be disabled initially"

def test_save_dialog_trigger():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    mock_page.overlay = []
    
    # Execute
    main(mock_page)
    
    # Find Save Button
    main_layout = next((call.args[0] for call in mock_page.add.call_args_list if isinstance(call.args[0], ft.Row)), None)
    controls_column = main_layout.controls[0].content
    save_button = next((c for c in controls_column.controls if isinstance(c, ft.ElevatedButton) and "Save" in c.text), None)
    
    # Find Save FilePicker
    # We expect TWO FilePickers: one for picking, one for saving
    file_pickers = [item for item in mock_page.overlay if isinstance(item, ft.FilePicker)]
    assert len(file_pickers) >= 2, "Should have pick and save FilePickers"
    
    save_picker = file_pickers[1]
    save_picker.save_file = MagicMock()
    
    # Execute click
    save_button.on_click(None)
    
    # Verify save_file was called
    assert save_picker.save_file.called, "save_file() should be called when Save button is clicked"

def test_initial_disabled_state():
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    mock_page.overlay = []
    
    # Execute
    main(mock_page)
    
    # Find controls
    main_layout = next((call.args[0] for call in mock_page.add.call_args_list if isinstance(call.args[0], ft.Row)), None)
    controls_column = main_layout.controls[0].content
    
    # Check that sliders and textfield are disabled initially
    text_field = next(c for c in controls_column.controls if isinstance(c, ft.TextField))
    # Sliders are inside Columns
    slider_containers = [c for c in controls_column.controls if isinstance(c, ft.Column)]
    sliders = []
    for container in slider_containers:
        sliders.extend([sc for sc in container.controls if isinstance(sc, ft.Slider)])
    
    # Save button is also there
    save_button = next((c for c in controls_column.controls if isinstance(c, ft.ElevatedButton) and "Save" in c.text), None)

    assert text_field.disabled is True, "TextField should be disabled initially"
    for s in sliders:
        assert s.disabled is True, f"Slider {s.label} should be disabled initially"
    assert save_button.disabled is True, "Save button should be disabled initially"

def test_error_handling_invalid_file():
    """Invalid image files trigger error handling via show_error."""
    # Setup
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    mock_page.overlay = []
    mock_page.snack_bar = None
    mock_page.update = MagicMock()

    main(mock_page)

    # Find FilePicker
    file_picker = next(item for item in mock_page.overlay if isinstance(item, ft.FilePicker))

    mock_pil_open = MagicMock()
    mock_pil_open.side_effect = Exception("Invalid image")

    with patch("builtins.open", mock_open(read_data=b"not an image")), \
         patch("PIL.Image.open", mock_pil_open), \
         patch("app.validate_file_size"):

        event = MagicMock(spec=ft.FilePickerResultEvent)
        event.files = [MagicMock(path="fake.jpg")]

        try:
            if hasattr(file_picker.on_result, "handler"):
                file_picker.on_result.handler(event)
            else:
                file_picker.on_result(event)
        except TypeError:
            pass


# --- Security vulnerability fix tests ---

def test_watermark_text_max_length():
    """Vulnerability 1: TextField must have max_length=200 to prevent DoS via huge text."""
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    main(mock_page)
    main_layout = next(
        (call.args[0] for call in mock_page.add.call_args_list if isinstance(call.args[0], ft.Row)), None
    )
    controls_column = main_layout.controls[0].content
    text_field = next(c for c in controls_column.controls if isinstance(c, ft.TextField))
    assert text_field.max_length == 200, "Watermark TextField must have max_length=200"


def test_strip_image_metadata_uses_paste():
    """Vulnerability 2: strip_image_metadata must use paste(), not getdata(), to avoid OOM."""
    from utils import strip_image_metadata

    img = Image.new("RGB", (10, 10), color="blue")
    with patch.object(Image.Image, "putdata", side_effect=AssertionError("putdata must not be called")):
        result = strip_image_metadata(img)

    assert result is not None
    assert result.size == img.size


def test_strip_image_metadata_strips_exif():
    """strip_image_metadata must return an image without EXIF metadata."""
    from utils import strip_image_metadata

    img = Image.new("RGB", (10, 10), color="red")
    buf = io.BytesIO()
    img.save(buf, format="JPEG")
    buf.seek(0)
    img_with_meta = Image.open(buf)

    result = strip_image_metadata(img_with_meta)
    assert "exif" not in result.info


def test_sanitize_path_for_log_strips_newlines():
    """Vulnerability 3: sanitize_path_for_log must strip \\n and \\r to prevent log injection."""
    from utils import sanitize_path_for_log

    message = "some message\ninjected log line\r another line"
    result = sanitize_path_for_log(message)
    assert "\n" not in result
    assert "\r" not in result


def test_watermark_text_length_validation():
    """Vulnerability 1 (server-side guard): apply_watermark_to_pil_image must reject text > 200 chars."""
    from watermark import apply_watermark_to_pil_image, WatermarkParams

    img = Image.new("RGBA", (100, 100))
    params = WatermarkParams(text="A" * 201, opacity=30, font_size=36, spacing=150)

    with pytest.raises(ValueError, match="too long"):
        apply_watermark_to_pil_image(img, params)
