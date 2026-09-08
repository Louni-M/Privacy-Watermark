"""Finder presentation, generated without Apple Events or an interactive desktop."""
import os

stage = defines["stage"]
format = "UDZO"
filesystem = "HFS+"
files = [os.path.join(stage, "Passport Filigrane.app"), os.path.join(stage, "Install.txt")]
symlinks = {"Applications": "/Applications"}
background = os.path.join(stage, "background.png")
icon = os.path.join(stage, "Passport Filigrane.app/Contents/Resources/app_icon.icns")
window_rect = ((160, 120), (660, 440))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
icon_size = 88
text_size = 13
icon_locations = {
    "Passport Filigrane.app": (175, 200),
    "Applications": (485, 200),
    "Install.txt": (330, 355),
}
# Do not set FinderInfo on the signed app (even to hide its extension):
# codesign --verify --strict rejects that metadata. Finder knows .app bundles.
