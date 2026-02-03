"""
Create test PDF fixtures for quality validation testing.

Generates:
1. Multi-page PDF with mixed content (text, vectors, images)
2. High-resolution PDF for zoom testing
"""

import fitz  # PyMuPDF
from PIL import Image, ImageDraw
import io

def create_multipage_pdf():
    """Create a multi-page test PDF with text, vectors, and sample image."""
    print("Creating multi-page test PDF...")

    doc = fitz.open()

    # Page 1: Text content
    page1 = doc.new_page(width=595, height=842)  # A4
    page1.insert_text((50, 50), "Test Document - Page 1", fontsize=24, color=(0, 0, 0))
    page1.insert_text((50, 100), "Text Content Page", fontsize=18, color=(0, 0, 0.5))

    # Add various text sizes
    y = 150
    for size in [10, 12, 14, 16, 18, 20, 24]:
        page1.insert_text((50, y), f"Font size {size}pt: The quick brown fox jumps over the lazy dog.", fontsize=size, color=(0, 0, 0))
        y += size + 10

    # Add unicode text
    page1.insert_text((50, y), "Unicode: àéîöü ÀÉÎÖÜ çñ ¿¡ €£¥", fontsize=14, color=(0, 0, 0))

    # Page 2: Vector shapes
    page2 = doc.new_page(width=595, height=842)
    page2.insert_text((50, 50), "Test Document - Page 2", fontsize=24, color=(0, 0, 0))
    page2.insert_text((50, 100), "Vector Graphics Page", fontsize=18, color=(0, 0, 0.5))

    # Draw various shapes
    page2.draw_line((50, 150), (545, 150), color=(1, 0, 0), width=2)
    page2.draw_rect(fitz.Rect(50, 180, 250, 280), color=(0, 1, 0), width=2)
    page2.draw_circle(fitz.Point(350, 230), 50, color=(0, 0, 1), width=2)
    page2.draw_quad(fitz.Quad((50, 320), (250, 320), (250, 420), (50, 420)), color=(1, 0, 1), width=2)

    # Filled shapes
    page2.draw_rect(fitz.Rect(300, 320, 450, 420), color=(0.5, 0.5, 0), fill=(1, 1, 0.5))

    # Page 3: Mixed content with embedded image
    page3 = doc.new_page(width=595, height=842)
    page3.insert_text((50, 50), "Test Document - Page 3", fontsize=24, color=(0, 0, 0))
    page3.insert_text((50, 100), "Mixed Content Page", fontsize=18, color=(0, 0, 0.5))

    # Create a simple test image (gradient)
    img_width, img_height = 200, 150
    test_img = Image.new("RGB", (img_width, img_height))
    draw = ImageDraw.Draw(test_img)

    # Draw gradient
    for y in range(img_height):
        color_value = int((y / img_height) * 255)
        draw.line([(0, y), (img_width, y)], fill=(color_value, 100, 255 - color_value))

    # Draw some shapes on the image
    draw.rectangle([20, 20, 180, 130], outline=(255, 255, 255), width=3)
    draw.ellipse([60, 40, 140, 110], outline=(255, 0, 0), width=2)

    # Convert to bytes
    img_byte_arr = io.BytesIO()
    test_img.save(img_byte_arr, format='PNG')

    # Insert image
    page3.insert_image(fitz.Rect(50, 150, 250, 300), stream=img_byte_arr.getvalue())

    # Add text after image
    page3.insert_text((50, 330), "This page contains text, an embedded image, and vectors.", fontsize=12)
    page3.draw_line((50, 350), (545, 350), color=(0, 0, 0), width=1, dashes="[3 2]")

    # Page 4: Dense text (like a document page)
    page4 = doc.new_page(width=595, height=842)
    page4.insert_text((50, 50), "Test Document - Page 4", fontsize=24, color=(0, 0, 0))
    page4.insert_text((50, 100), "Dense Text Content", fontsize=18, color=(0, 0, 0.5))

    # Simulate paragraph text
    lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."

    y = 140
    for _ in range(10):
        page4.insert_text((50, y), lorem[:80], fontsize=11, color=(0, 0, 0))
        y += 20
        page4.insert_text((50, y), lorem[80:], fontsize=11, color=(0, 0, 0))
        y += 30

    # Save
    output_path = "test_fixtures/multipage_test.pdf"
    doc.save(output_path)
    print(f"✓ Created: {output_path}")
    print(f"  - 4 pages with mixed content")
    print(f"  - Text, vectors, embedded image")

    doc.close()
    return output_path


def create_highres_pdf():
    """Create a high-resolution test PDF for zoom testing."""
    print("\nCreating high-resolution test PDF...")

    doc = fitz.open()
    page = doc.new_page(width=595, height=842)  # A4

    # Title
    page.insert_text((50, 50), "High-Resolution Quality Test", fontsize=28, color=(0, 0, 0))

    # Instructions
    page.insert_text((50, 100), "Zoom to 400% to verify text sharpness", fontsize=14, color=(0.5, 0, 0))

    # Small text (critical for quality testing)
    y = 140
    sizes = [6, 7, 8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32]

    for size in sizes:
        page.insert_text((50, y), f"{size}pt: ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", fontsize=size, color=(0, 0, 0))
        y += size + 8

    # Fine details: thin lines at different widths
    y += 20
    page.insert_text((50, y), "Line width test (0.5, 1, 1.5, 2, 3 points):", fontsize=12, color=(0, 0, 0))
    y += 30

    line_widths = [0.5, 1, 1.5, 2, 3]
    for width in line_widths:
        page.draw_line((50, y), (545, y), color=(0, 0, 0), width=width)
        page.insert_text((555, y - 5), f"{width}pt", fontsize=8, color=(0, 0, 0))
        y += 20

    # Small shapes for detail testing
    y += 20
    page.insert_text((50, y), "Detail test:", fontsize=12, color=(0, 0, 0))
    y += 30

    # Tiny squares
    for i in range(10):
        size = 5 + i * 3
        page.draw_rect(fitz.Rect(50 + i * 50, y, 50 + i * 50 + size, y + size), color=(0, 0, 0), width=0.5)

    # Quality comparison text
    y += 80
    page.insert_text((50, y), "AFTER WATERMARKING:", fontsize=14, fontname="helv", color=(1, 0, 0))
    y += 30
    page.insert_text((50, y), "• This text MUST remain sharp at 400% zoom", fontsize=12, color=(0, 0, 0))
    y += 25
    page.insert_text((50, y), "• No JPEG artifacts or pixelation allowed", fontsize=12, color=(0, 0, 0))
    y += 25
    page.insert_text((50, y), "• Original vectors must stay crisp", fontsize=12, color=(0, 0, 0))
    y += 25
    page.insert_text((50, y), "• Text must remain selectable", fontsize=12, color=(0, 0, 0))

    # Reference grid for alignment
    y += 50
    page.insert_text((50, y), "Alignment Grid:", fontsize=10, color=(0.5, 0.5, 0.5))
    y += 20

    # Draw grid
    for x in range(50, 550, 50):
        page.draw_line((x, y), (x, y + 100), color=(0.8, 0.8, 0.8), width=0.25)

    for grid_y in range(0, 101, 10):
        page.draw_line((50, y + grid_y), (545, y + grid_y), color=(0.8, 0.8, 0.8), width=0.25)

    # Save
    output_path = "test_fixtures/highres_test.pdf"
    doc.save(output_path)
    print(f"✓ Created: {output_path}")
    print(f"  - Single page with fine details")
    print(f"  - Font sizes 6pt to 32pt")
    print(f"  - Line widths 0.5pt to 3pt")
    print(f"  - Grid for alignment testing")

    doc.close()
    return output_path


def create_identity_document_mock():
    """Create a mock identity document for realistic testing."""
    print("\nCreating mock identity document PDF...")

    doc = fitz.open()
    page = doc.new_page(width=595, height=842)

    # Border
    page.draw_rect(fitz.Rect(30, 30, 565, 812), color=(0, 0, 0.5), width=3)

    # Header
    page.insert_text((50, 60), "IDENTITY DOCUMENT", fontsize=24, fontname="helv", color=(0, 0, 0.5))
    page.insert_text((50, 90), "Mock Document for Testing", fontsize=10, color=(0.5, 0, 0))

    # Photo placeholder
    page.draw_rect(fitz.Rect(400, 120, 520, 270), color=(0, 0, 0), width=2, fill=(0.9, 0.9, 0.9))
    page.insert_text((430, 200), "PHOTO", fontsize=16, color=(0.5, 0.5, 0.5))

    # Document fields
    y = 130
    fields = [
        ("Document No:", "AB123456"),
        ("Surname:", "DOE"),
        ("Given Names:", "JOHN WILLIAM"),
        ("Nationality:", "TESTLAND"),
        ("Date of Birth:", "01 JAN 1990"),
        ("Place of Birth:", "TEST CITY"),
        ("Sex:", "M"),
        ("Date of Issue:", "01 JAN 2025"),
        ("Date of Expiry:", "01 JAN 2035"),
        ("Authority:", "TEST AUTHORITY"),
    ]

    for label, value in fields:
        page.insert_text((50, y), label, fontsize=10, fontname="helv", color=(0, 0, 0))
        page.insert_text((200, y), value, fontsize=12, color=(0, 0, 0))
        y += 30

    # Machine-readable zone (MRZ)
    y = 720
    page.draw_rect(fitz.Rect(50, y - 10, 545, y + 60), fill=(0.95, 0.95, 0.95))
    page.insert_text((50, y + 10), "P<TESTDOE<<JOHN<WILLIAM<<<<<<<<<<<<<<<<<<<<<<<<", fontsize=10, fontname="cour", color=(0, 0, 0))
    page.insert_text((50, y + 30), "AB123456<9TEST9001011M3501011<<<<<<<<<<<<<<06", fontsize=10, fontname="cour", color=(0, 0, 0))

    # Warning text
    page.insert_text((50, 790), "This is a mock document for testing purposes only.", fontsize=8, color=(0.5, 0, 0))

    # Save
    output_path = "test_fixtures/identity_document_mock.pdf"
    doc.save(output_path)
    print(f"✓ Created: {output_path}")
    print(f"  - Realistic identity document layout")
    print(f"  - Fine text details")
    print(f"  - Machine-readable zone")

    doc.close()
    return output_path


if __name__ == "__main__":
    print("="*60)
    print("Creating Test PDF Fixtures")
    print("="*60)

    multipage = create_multipage_pdf()
    highres = create_highres_pdf()
    identity = create_identity_document_mock()

    print("\n" + "="*60)
    print("Test Fixtures Created Successfully")
    print("="*60)
    print(f"\nGenerated files:")
    print(f"  1. {multipage}")
    print(f"  2. {highres}")
    print(f"  3. {identity}")
    print(f"\nThese fixtures will be used for:")
    print(f"  - Unit testing vector watermark function")
    print(f"  - Quality validation at 400% zoom")
    print(f"  - Integration testing")
    print(f"  - Acceptance criteria verification")
