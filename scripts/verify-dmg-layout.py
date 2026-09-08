"""Check saved Finder presentation without launching Finder."""
from pathlib import Path
import sys
from ds_store import DSStore
from mac_alias import Alias

mount = Path(sys.argv[1])
with DSStore.open(str(mount / ".DS_Store"), "r") as store:
    window = store["."]["bwsp"]
    view = store["."]["icvp"]
    assert window["WindowBounds"] == "{{160, 120}, {660, 440}}", "Unexpected window bounds"
    assert not any(window[key] for key in ("ShowToolbar", "ShowSidebar", "ShowStatusBar", "ShowPathbar", "ShowTabView"))
    assert view["arrangeBy"] == "none" and view["iconSize"] == 88 and view["textSize"] == 13
    assert view["backgroundType"] == 2
    alias = Alias.from_bytes(view["backgroundImageAlias"])
    assert alias.target.filename == ".background.png", "Background alias points to wrong file"
    assert store["Passport Filigrane.app"]["Iloc"] == (175, 200)
    assert store["Applications"]["Iloc"] == (485, 200)
    assert store["Install.txt"]["Iloc"] == (330, 355)
print("Verified saved Finder layout and background alias")
