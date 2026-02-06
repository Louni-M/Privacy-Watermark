# -*- mode: python ; coding: utf-8 -*-

# IMPORTANT: Build with PyInstaller >= 6.0.0 (CVE-2025-59042 fix)
# IMPORTANT: Before publishing, replace codesign_identity and entitlements_file
# with your Apple Developer credentials. See SECURITY.md for details.

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=[('pdf_processing.py', '.')],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='Passport Filigrane',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['assets/app_icon.icns'],
)
coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Passport Filigrane',
)
app = BUNDLE(
    coll,
    name='Passport Filigrane.app',
    icon='assets/app_icon.icns',
    bundle_identifier='com.passportfiligrane.app',
)
