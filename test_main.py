from unittest.mock import MagicMock
import pytest
import flet as ft
from main import main

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
    assert file_picker.file_type == ft.FilePickerFileType.IMAGE, "FilePicker should be configured for images"
    
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
    assert button.text == "Sélectionner une image"

def test_generate_preview_resizing():
    from PIL import Image
    from main import generate_preview
    import io
    
    # Create a large test image (1600x1200)
    large_image = Image.new("RGB", (1600, 1200), color="red")
    img_byte_arr = io.BytesIO()
    large_image.save(img_byte_arr, format='PNG')
    img_byte_arr.seek(0)
    
    # Execute generate_preview (should resize to max 800px width)
    preview_bytes = generate_preview(img_byte_arr)
    
    # Verify results
    result_img = Image.open(io.BytesIO(preview_bytes))
    assert result_img.width <= 800
    # Ratio should be preserved: 1600/1200 = 800/600
    assert result_img.width == 800
    assert result_img.height == 600
