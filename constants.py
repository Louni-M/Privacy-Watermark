"""Application-wide constants for Passport Filigrane."""

# --- Security / input validation limits ---
MAX_FILE_SIZE_BYTES = 100 * 1024 * 1024  # 100 MB
MAX_PDF_PAGES = 50
MAX_IMAGE_DIMENSION = 20000  # pixels per side

# --- Export filename prefix ---
EXPORT_FILENAME_PREFIX = "export_filigree"

# --- JPEG quality settings ---
# Standard export (image watermark output, PDF-to-images): visually lossless at 90.
JPEG_EXPORT_QUALITY = 90
# Secure raster mode renders pages at high DPI; higher quality preserves
# watermark fidelity before the intentional rasterization step.
JPEG_SECURE_QUALITY = 95

# --- Watermark color maps ---
# For PyMuPDF vector watermarks (float 0.0-1.0 per channel)
WATERMARK_COLOR_MAP = {
    "White": (1.0, 1.0, 1.0),
    "Black": (0.0, 0.0, 0.0),
    "Gray": (0.5, 0.5, 0.5),
}

# For Pillow raster watermarks (int 0-255 per channel)
PIL_COLOR_MAP = {
    "White": (255, 255, 255),
    "Black": (0, 0, 0),
    "Gray": (128, 128, 128),
}

# Orientation options: angle in degrees
# Ascending (↗): text goes from bottom-left to top-right
# Descending (↘): text goes from top-left to bottom-right
WATERMARK_ORIENTATION_MAP = {
    "Ascending (↗)": 45,    # Counter-clockwise rotation
    "Descending (↘)": -45,  # Clockwise rotation
}

# --- UI colors ---
BG_PRIMARY = "#0f172a"
BG_SECONDARY = "#1e293b"
ACCENT_PINK = "#ec4899"
ACCENT_PINK_LIGHT = "#f472b6"
ACCENT_GREEN = "#10b981"
ACCENT_YELLOW = "#f59e0b"
ACCENT_PURPLE = "#8b5cf6"
ACCENT_CYAN = "#06b6d4"
TEXT_WHITE = "#ffffff"
TEXT_MUTED = "#aaaaaa"
TEXT_WARNING = "#ff9800"
