import flet as ft

def main(page: ft.Page):
    page.title = "Passport Filigrane"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0
    page.update()

if __name__ == "__main__":
    ft.app(target=main)
