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
    a.binaries,
    a.datas,
    [],
    name='Passport Filigrane',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,      # TODO: Set Apple Developer identity before release
    entitlements_file=None,      # TODO: Create entitlements.plist for macOS sandbox
    icon=['assets/app_icon.icns'],
)
app = BUNDLE(
    exe,
    name='Passport Filigrane.app',
    icon='assets/app_icon.icns',
    bundle_identifier='com.passportfiligrane.app',
)
