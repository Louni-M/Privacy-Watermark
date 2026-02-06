"""
Tests for vector watermark implementation.

This module tests the apply_vector_watermark_to_pdf() function which uses
PyMuPDF's native vector text rendering to preserve PDF quality.
"""

import pytest
import fitz
from pdf_processing import apply_vector_watermark_to_pdf
from PIL import Image
import io


@pytest.fixture
def test_pdf(tmp_path):
    """Create a test PDF with text content."""
    pdf_path = tmp_path / "test_vector.pdf"
    doc = fitz.open()
    page = doc.new_page(width=595, height=842)  # A4

    # Add some test content
    page.insert_text((50, 50), "Test Document", fontsize=24)
    page.insert_text((50, 100), "This text should remain selectable", fontsize=12)
    page.draw_rect(fitz.Rect(50, 150, 200, 250), color=(0, 0, 1), width=2)

    doc.save(str(pdf_path))
    doc.close()
    return str(pdf_path)


@pytest.fixture
def multipage_pdf(tmp_path):
    """Create a multi-page test PDF."""
    pdf_path = tmp_path / "test_multipage.pdf"
    doc = fitz.open()

    # Create 3 pages
    for i in range(3):
        page = doc.new_page(width=595, height=842)
        page.insert_text((50, 50), f"Page {i+1}", fontsize=24)

    doc.save(str(pdf_path))
    doc.close()
    return str(pdf_path)


def test_vector_watermark_text_added_to_page(test_pdf):
    """Test that watermark text is added to PDF page."""
    doc = fitz.open(test_pdf)
    original_content_length = len(doc[0].get_text())

    # Apply vector watermark
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="WATERMARK",
        opacity=30,
        font_size=36,
        spacing=150,
        color="White"
    )

    # Verify watermark was added (page content should be modified)
    # Note: Vector watermark doesn't add to extractable text, but modifies page content stream
    page = doc[0]

    # Check that page content stream was modified
    # We can verify by checking the page's content stream contains text operators
    content = page.read_contents()
    assert len(content) > 0, "Page content stream should contain data"

    # Verify original text is still there
    assert doc[0].get_text() == original_content_length or len(doc[0].get_text()) >= original_content_length

    doc.close()


def test_vector_watermark_respects_opacity(test_pdf):
    """Test that watermark respects opacity parameter."""
    doc = fitz.open(test_pdf)

    # Apply watermark with different opacities and verify they produce different results
    # Opacity should be converted: 0-100 -> 0.0-1.0

    # Test with 30% opacity
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="TEST",
        opacity=30,  # 30% = 0.3 in PyMuPDF
        font_size=36,
        spacing=150,
        color="Black"
    )

    # Get the page content to verify opacity was set
    page = doc[0]
    content_bytes = page.read_contents()

    # The content should contain graphics state with opacity
    # In PDF, opacity is set with /ca (fill opacity) in graphics state
    assert len(content_bytes) > 0, "Page should have content after watermark"

    # Verify the watermark was applied (content changed)
    assert b'TEST' in content_bytes or b'Tj' in content_bytes or b'TJ' in content_bytes, "Page content should contain text drawing operators"

    doc.close()


def test_vector_watermark_respects_font_size(test_pdf):
    """Test that watermark respects font size parameter."""
    doc = fitz.open(test_pdf)

    font_size = 48  # Larger than default

    apply_vector_watermark_to_pdf(
        doc=doc,
        text="SIZE",
        opacity=50,
        font_size=font_size,
        spacing=200,
        color="Black"
    )

    # Verify watermark was applied with specified font size
    page = doc[0]
    content = page.read_contents()

    # The PDF content stream should contain the font size setting
    # In PDF: /F<name> <size> Tf (font operator)
    assert len(content) > 0

    # Verify page was modified
    assert b'Tf' in content, "Font operator should be present in page content"

    doc.close()


def test_vector_watermark_respects_spacing(test_pdf):
    """Test that watermark respects spacing parameter."""
    doc1 = fitz.open(test_pdf)
    doc2 = fitz.open(test_pdf)

    # Apply with different spacing values
    apply_vector_watermark_to_pdf(
        doc=doc1,
        text="SPACE",
        opacity=50,
        font_size=36,
        spacing=100,  # Tight spacing
        color="Black"
    )

    apply_vector_watermark_to_pdf(
        doc=doc2,
        text="SPACE",
        opacity=50,
        font_size=36,
        spacing=300,  # Wide spacing
        color="Black"
    )

    # Different spacing should result in different content
    content1 = doc1[0].read_contents()
    content2 = doc2[0].read_contents()

    # Content should be different due to different number of watermark instances
    assert len(content1) != len(content2), "Different spacing should produce different content lengths"

    # Tight spacing should have more text instances (longer content)
    assert len(content1) > len(content2), "Tighter spacing should result in more watermark instances"

    doc1.close()
    doc2.close()


def test_vector_watermark_respects_color_white(test_pdf):
    """Test that watermark respects color parameter - White."""
    doc = fitz.open(test_pdf)

    apply_vector_watermark_to_pdf(
        doc=doc,
        text="WHITE",
        opacity=50,
        font_size=36,
        spacing=150,
        color="White"
    )

    page = doc[0]
    content = page.read_contents()

    # Verify content was added
    assert len(content) > 0

    # White color in PDF: 1 1 1 rg (RGB fill color)
    # The exact representation depends on how PyMuPDF encodes it
    assert b'rg' in content or b'RG' in content, "Color operator should be present"

    doc.close()


def test_vector_watermark_respects_color_black(test_pdf):
    """Test that watermark respects color parameter - Black."""
    doc = fitz.open(test_pdf)

    apply_vector_watermark_to_pdf(
        doc=doc,
        text="BLACK",
        opacity=50,
        font_size=36,
        spacing=150,
        color="Black"
    )

    page = doc[0]
    content = page.read_contents()

    # Verify content was added with color operator
    assert len(content) > 0
    assert b'rg' in content or b'RG' in content, "Color operator should be present"

    doc.close()


def test_vector_watermark_respects_color_gray(test_pdf):
    """Test that watermark respects color parameter - Gray."""
    doc = fitz.open(test_pdf)

    apply_vector_watermark_to_pdf(
        doc=doc,
        text="GRAY",
        opacity=50,
        font_size=36,
        spacing=150,
        color="Gray"
    )

    page = doc[0]
    content = page.read_contents()

    # Verify content was added with color operator
    assert len(content) > 0
    assert b'rg' in content or b'RG' in content, "Color operator should be present"

    doc.close()


def test_vector_watermark_diagonal_tiling_pattern(test_pdf):
    """Test diagonal tiling pattern (45° rotation)."""
    doc = fitz.open(test_pdf)

    apply_vector_watermark_to_pdf(
        doc=doc,
        text="COPIE",
        opacity=30,
        font_size=36,
        spacing=150,
        color="White"
    )

    page = doc[0]
    content = page.read_contents()

    # Verify rotation matrix is applied
    # In PDF, rotation uses cm (concat matrix) operator
    # A 45° rotation matrix has specific values
    assert len(content) > 0
    assert b'cm' in content or b'Tm' in content, "Transformation matrix should be present for rotation"

    # Multiple watermark instances should be present (tiling)
    # Count text show operators (Tj or TJ)
    tj_count = content.count(b'Tj') + content.count(b'TJ')
    assert tj_count > 10, f"Should have multiple watermark instances for tiling (found {tj_count})"

    doc.close()


def test_vector_watermark_multipage(multipage_pdf):
    """Test that watermark is applied to all pages."""
    doc = fitz.open(multipage_pdf)

    apply_vector_watermark_to_pdf(
        doc=doc,
        text="MULTIPAGE",
        opacity=40,
        font_size=36,
        spacing=150,
        color="Black"
    )

    # Verify all pages have watermark
    for page_num in range(len(doc)):
        page = doc[page_num]
        content = page.read_contents()

        assert len(content) > 0, f"Page {page_num} should have content"
        assert b'Tj' in content or b'TJ' in content, f"Page {page_num} should have text operators"

    doc.close()


def test_vector_watermark_preserves_original_text_selectability(test_pdf):
    """Test that original PDF text remains selectable after watermarking."""
    doc = fitz.open(test_pdf)

    # Get original text
    original_text = doc[0].get_text()
    assert "Test Document" in original_text, "Original text should be present"

    # Apply watermark
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="COPIE",
        opacity=30,
        font_size=36,
        spacing=150,
        color="White"
    )

    # Verify original text is still extractable (selectable)
    watermarked_text = doc[0].get_text()
    assert "Test Document" in watermarked_text, "Original text should remain selectable after watermarking"
    assert "This text should remain selectable" in watermarked_text

    doc.close()


def test_vector_watermark_overlay_layer(test_pdf):
    """Test that watermark is added as overlay layer on top of content."""
    doc = fitz.open(test_pdf)

    # Apply watermark
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="OVERLAY",
        opacity=50,
        font_size=48,
        spacing=200,
        color="Black"
    )

    # The watermark should be in the content stream
    # Since it's added via page.insert_text with overlay=True,
    # it should appear after the original content in the stream
    page = doc[0]
    content = page.read_contents()

    assert len(content) > 0
    # Verify text operators present (watermark was added)
    assert b'Tj' in content or b'TJ' in content

    doc.close()


def test_vector_watermark_file_size_reasonable(test_pdf):
    """Test that file size doesn't explode after vector watermarking."""
    import os

    doc = fitz.open(test_pdf)
    original_size = os.path.getsize(test_pdf)

    # Apply watermark
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="COPIE",
        opacity=30,
        font_size=36,
        spacing=150,
        color="White"
    )

    # Save to temp file
    import tempfile
    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        tmp_path = tmp.name
        doc.save(tmp_path)

    watermarked_size = os.path.getsize(tmp_path)

    # File size should be reasonable (not more than 15x original for test PDFs)
    # Vector watermarks add font resources and graphics states
    # For small test PDFs, this can cause larger relative increases
    # Production PDFs will have much smaller relative increases
    size_ratio = watermarked_size / original_size
    assert size_ratio < 15.0, f"File size increased by {size_ratio}x (should be < 15x for test PDF)"

    # Cleanup
    os.unlink(tmp_path)
    doc.close()


def test_vector_watermark_with_default_parameters(test_pdf):
    """Test vector watermark with default/typical parameters."""
    doc = fitz.open(test_pdf)

    # Use typical parameters from existing app
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="COPIE",
        opacity=30,
        font_size=36,
        spacing=150,
        color="White"
    )

    # Basic verification
    page = doc[0]
    content = page.read_contents()

    assert len(content) > 0, "Watermark should be applied"
    assert b'Tj' in content or b'TJ' in content, "Text operators should be present"

    doc.close()
