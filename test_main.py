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
    assert mock_page.padding == 0 # Based on spec-like requirements often used in Flet for clean layouts
