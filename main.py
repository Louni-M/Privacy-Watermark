"""Thin entry point for Passport Filigrane. UI logic lives in app.py."""
import flet as ft
from app import PassportFiligraneApp


def main(page: ft.Page):
    PassportFiligraneApp(page)


if __name__ == "__main__":
    ft.app(target=main)
