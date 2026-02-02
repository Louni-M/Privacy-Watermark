# Track Spec: MacOS App Packaging & Icon

## Problem
The application currently runs as a Python script (`main.py`). Users have to use a terminal and a virtual environment to launch it, which is not user-friendly for non-technical people.

## Solution
Package the application into a standalone macOS `.app` bundle with a custom icon. This will allow users to:
1. Double-click an icon to launch.
2. Place the app in the `/Applications` folder.
3. Use the app without needing to touch the terminal or manage Python environments.

## Requirements

### Functional
- **Standalone Bundle**: A `.app` file that contains all dependencies (Flet, PyMuPDF, Pillow).
- **Custom Icon**: The app should have a unique, premium icon in the Dock and Finder.
- **Easy Launch**: The app should open the GUI directly without a terminal window appearing.

### Non-Functional
- **Size**: Optimized bundle size (under 100MB if possible).
- **Compatibility**: Must work on macOS (Intel/Silicon).
- **No Xcode**: Preferred to use Python-based packaging tools (like `flet pack` or `PyInstaller`) to maintain the "No Xcode" project constraint.

## Acceptance Criteria
- [ ] AC-1: A `Passport Filigrane.app` is generated.
- [ ] AC-2: The app launches correctly from the Applications folder.
- [ ] AC-3: The generated icon is visible in the Finder and Dock.
- [ ] AC-4: All features (PDF/Image watermarking) work within the standalone app.

## Out of Scope
- Apple Developer Program notarization (requires paid account and Xcode).
- DMG installer creation (can be done later but for now a .app is enough).
