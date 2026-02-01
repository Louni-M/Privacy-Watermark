import flet as ft

def main(page: ft.Page):
    page.title = "Passport Filigrane"
    page.theme_mode = ft.ThemeMode.DARK
    page.padding = 0

    # Panneau de contrôles (gauche)
    controls_panel = ft.Column(
        width=300,
        controls=[
            ft.Text("Contrôles", size=18, weight=ft.FontWeight.BOLD),
        ]
    )

    # Panneau de prévisualisation (droite)
    preview_panel = ft.Column(
        expand=True,
        controls=[
            ft.Text("Prévisualisation", size=18, weight=ft.FontWeight.BOLD),
        ]
    )

    # Layout principal
    main_layout = ft.Row(
        controls=[
            controls_panel,
            preview_panel,
        ],
        expand=True,
    )

    page.add(main_layout)
    page.update()

if __name__ == "__main__":
    ft.app(target=main)
