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
