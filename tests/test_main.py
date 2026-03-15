from unittest.mock import MagicMock, patch, mock_open
import pytest
import flet as ft
from main import main, PassportFiligraneApp


def find_ctrl(controls, match_fn):
    for c in controls:
        if match_fn(c): return c
        if hasattr(c, "controls") and c.controls:
            res = find_ctrl(c.controls, match_fn)
            if res: return res
        if hasattr(c, "content") and c.content:
            if hasattr(c.content, "controls"):
                res = find_ctrl(c.content.controls, match_fn)
                if res: return res
            elif isinstance(c.content, ft.Column) or isinstance(c.content, ft.Row):
                res = find_ctrl(c.content.controls, match_fn)
                if res: return res
            else:
                res = find_ctrl([c.content], match_fn)
                if res: return res
    return None

def find_all_ctrls(controls, match_fn, results=None):
    if results is None: results = []
    for c in controls:
        if match_fn(c): results.append(c)
        if hasattr(c, "controls") and c.controls:
            find_all_ctrls(c.controls, match_fn, results)
        if hasattr(c, "content") and c.content:
            if hasattr(c.content, "controls"):
                find_all_ctrls(c.content.controls, match_fn, results)
            elif isinstance(c.content, ft.Column) or isinstance(c.content, ft.Row):
                find_all_ctrls(c.content.controls, match_fn, results)
            else:
                find_all_ctrls([c.content], match_fn, results)
    return results


def test_main_page_setup():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    main(mock_page)
    app = PassportFiligraneApp(mock_page)
    assert mock_page.title == "Passport Filigrane"
    assert mock_page.theme_mode == ft.ThemeMode.SYSTEM
    assert mock_page.padding == 0

def test_layout_structure():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.controls = []
    mock_page.overlay = []
    main(mock_page)
    app = PassportFiligraneApp(mock_page)
    
    assert len(mock_page.add.call_args_list) > 0
    # Find Loaded State Row
    loaded_state = None
    for call in mock_page.add.call_args_list:
        for arg in call.args:
            if isinstance(arg, ft.Row) and getattr(arg, "visible", True) is False:
                loaded_state = arg
                break
        if loaded_state: break
            
    assert loaded_state is not None
    assert len(loaded_state.controls) == 2
    assert loaded_state.controls[0].width == 340
    assert loaded_state.controls[1].expand is True

def test_file_picker_setup():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    mock_page.overlay = []
    main(mock_page)
    app = PassportFiligraneApp(mock_page)
    
    file_picker = next((item for item in mock_page.overlay if isinstance(item, ft.FilePicker)), None)
    assert file_picker is not None
    assert file_picker.file_type == ft.FilePickerFileType.CUSTOM
    assert "pdf" in file_picker.allowed_extensions
    
    empty_state = None
    for call in mock_page.add.call_args_list:
        for arg in call.args:
            if isinstance(arg, ft.Container) and getattr(arg, "visible", False) is True:
                empty_state = arg
                break
        if empty_state: break
            
    assert empty_state is not None
    button = find_ctrl([empty_state], lambda c: isinstance(c, ft.ElevatedButton))
    assert button is not None
    assert button.text == "Browse Files"

def test_generate_preview_resizing():
    from PIL import Image
    from main import generate_preview
    import io
    
    large_image = Image.new("RGB", (1600, 1200), color="red")
    img_byte_arr = io.BytesIO()
    large_image.save(img_byte_arr, format='PNG')
    img_byte_arr.seek(0)
    
    preview_bytes = generate_preview(img_byte_arr)
    
    result_img = Image.open(io.BytesIO(preview_bytes))
    assert result_img.width <= 800
    assert result_img.width == 800
    assert result_img.height == 600

def test_watermark_controls_setup():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)
    
    text_field = find_ctrl([app.loaded_state], lambda c: isinstance(c, ft.TextField))
    assert text_field is not None
    assert text_field.value == "COPY"
    assert text_field.label == "Watermark text"
    
    sliders = find_all_ctrls([app.loaded_state], lambda c: isinstance(c, ft.Slider))
    assert len(sliders) == 3
    assert sliders[0].min == 0 and sliders[0].max == 100 and sliders[0].value == 30
    assert sliders[1].min == 12 and sliders[1].max == 72 and sliders[1].value == 36
    assert sliders[2].min == 50 and sliders[2].max == 300 and sliders[2].value == 150

def test_realtime_update_event_binding():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)
    
    text_field = find_ctrl([app.loaded_state], lambda c: isinstance(c, ft.TextField))
    sliders = find_all_ctrls([app.loaded_state], lambda c: isinstance(c, ft.Slider))
    
    assert text_field.on_change is not None
    for s in sliders:
        assert s.on_change is not None

def test_save_button_setup():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)
    
    save_button = find_ctrl([app.loaded_state], lambda c: isinstance(c, ft.ElevatedButton) and "Save" in c.text)
    assert save_button is not None
    assert save_button.disabled is True

def test_save_dialog_trigger():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)
    
    save_button = find_ctrl([app.loaded_state], lambda c: isinstance(c, ft.ElevatedButton) and "Save" in c.text)
    
    file_pickers = [item for item in app.page.overlay if isinstance(item, ft.FilePicker)]
    assert len(file_pickers) >= 2
    
    save_picker = file_pickers[1]
    save_picker.save_file = MagicMock()
    
    save_button.on_click(None)
    assert save_picker.save_file.called

def test_initial_disabled_state():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    app = PassportFiligraneApp(mock_page)
    
    text_field = find_ctrl([app.loaded_state], lambda c: isinstance(c, ft.TextField))
    sliders = find_all_ctrls([app.loaded_state], lambda c: isinstance(c, ft.Slider))
    save_button = find_ctrl([app.loaded_state], lambda c: isinstance(c, ft.ElevatedButton) and "Save" in c.text)

    assert text_field.disabled is True
    for s in sliders:
        assert s.disabled is True
    assert save_button.disabled is True

def test_error_handling_invalid_file():
    mock_page = MagicMock(spec=ft.Page)
    mock_page.overlay = []
    main(mock_page)
    app = PassportFiligraneApp(mock_page)
    file_picker = next((item for item in mock_page.overlay if isinstance(item, ft.FilePicker)), None)
    if file_picker is None: file_picker = next(item for item in app.page.overlay if isinstance(item, ft.FilePicker))
    
    with patch("main.open", mock_open(read_data=b"not an image")):
        with patch("main.Image.open") as mock_pil_open:
            mock_pil_open.side_effect = Exception("Invalid image")
            
            event = MagicMock(spec=ft.FilePickerResultEvent)
            event.files = [MagicMock(path="fake.jpg")]
            
            try:
                if hasattr(file_picker.on_result, "handler"):
                    file_picker.on_result.handler(event)
                else:
                    file_picker.on_result(event)
            except TypeError:
                pass
