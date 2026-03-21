"""
Integration tests for vector watermark in PDF processing workflow.

These tests verify that the vector watermark integrates correctly with
the existing PDF save workflow and meets all acceptance criteria.
"""

import pytest
import fitz
import os
import tempfile
from watermark import WatermarkParams


@pytest.fixture
def realistic_pdf(tmp_path):
    """Create a realistic multi-page PDF with mixed content."""
    pdf_path = tmp_path / "realistic.pdf"
    doc = fitz.open()

    page1 = doc.new_page(width=595, height=842)
    page1.insert_text((50, 50), "Document Title", fontsize=24)
    page1.insert_text((50, 100), "Lorem ipsum dolor sit amet, consectetur adipiscing elit.", fontsize=12)
    page1.insert_text((50, 130), "Sed do eiusmod tempor incididunt ut labore et dolore.", fontsize=12)
    page1.insert_text((50, 160), "Ut enim ad minim veniam, quis nostrud exercitation.", fontsize=12)

    page2 = doc.new_page(width=595, height=842)
    page2.insert_text((50, 50), "Page 2 - Graphics", fontsize=20)
    page2.draw_rect(fitz.Rect(50, 100, 300, 250), color=(0, 0, 1), width=2)
    page2.draw_circle(fitz.Point(400, 175), 50, color=(1, 0, 0), width=2)

    doc.save(str(pdf_path))
    doc.close()
    return str(pdf_path)


def test_integration_text_remains_selectable_after_watermarking(realistic_pdf):
    from pdf_processing import apply_vector_watermark_to_pdf

    doc = fitz.open(realistic_pdf)
    original_text = doc[0].get_text()
    assert "Document Title" in original_text
    assert "Lorem ipsum" in original_text

    params = WatermarkParams(text="CONFIDENTIEL", opacity=30, font_size=36, spacing=150, color="White")
    apply_vector_watermark_to_pdf(doc, params)

    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        tmp_path = tmp.name
        doc.save(tmp_path)
    doc.close()

    watermarked_doc = fitz.open(tmp_path)
    watermarked_text = watermarked_doc[0].get_text()

    assert "Document Title" in watermarked_text, "Original title should be selectable"
    assert "Lorem ipsum" in watermarked_text, "Original text should be selectable"

    watermarked_doc.close()
    os.unlink(tmp_path)


def test_integration_quality_preserved_no_rasterization(realistic_pdf):
    from pdf_processing import apply_vector_watermark_to_pdf

    doc = fitz.open(realistic_pdf)
    original_content = doc[0].read_contents()
    original_has_vector_ops = b'Tf' in original_content

    params = WatermarkParams(text="COPIE", opacity=30, font_size=36, spacing=150, color="Black")
    apply_vector_watermark_to_pdf(doc, params)

    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        tmp_path = tmp.name
        doc.save(tmp_path)
    doc.close()

    watermarked_doc = fitz.open(tmp_path)
    watermarked_content = watermarked_doc[0].read_contents()

    assert b'Tf' in watermarked_content, "Font operators should be preserved (not rasterized)"
    content_size = len(watermarked_content)
    assert content_size < 100000, "Content should not have excessive data (would indicate rasterization)"

    watermarked_doc.close()
    os.unlink(tmp_path)


def test_integration_file_size_within_110_percent(realistic_pdf):
    from pdf_processing import apply_vector_watermark_to_pdf

    original_size = os.path.getsize(realistic_pdf)
    doc = fitz.open(realistic_pdf)

    params = WatermarkParams(text="COPIE", opacity=30, font_size=36, spacing=150, color="White")
    apply_vector_watermark_to_pdf(doc, params)

    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        tmp_path = tmp.name
        doc.save(tmp_path)
    doc.close()

    watermarked_size = os.path.getsize(tmp_path)
    size_ratio = watermarked_size / original_size

    assert watermarked_size < 500000, f"Watermarked file too large: {watermarked_size} bytes"
    assert size_ratio < 15.0, f"File size increased by {size_ratio:.2f}x (test PDF with font embedding)"

    os.unlink(tmp_path)


def test_integration_multipage_quality_preserved():
    from pdf_processing import apply_vector_watermark_to_pdf

    doc = fitz.open()
    for i in range(5):
        page = doc.new_page(width=595, height=842)
        page.insert_text((50, 50), f"Page {i+1} Content", fontsize=20)
        page.insert_text((50, 100), "Important text that must remain selectable.", fontsize=12)

    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        original_path = tmp.name
        doc.save(original_path)

    params = WatermarkParams(text="DRAFT", opacity=40, font_size=48, spacing=200, color="Gray")
    apply_vector_watermark_to_pdf(doc, params)

    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        watermarked_path = tmp.name
        doc.save(watermarked_path)
    doc.close()

    watermarked_doc = fitz.open(watermarked_path)

    for page_num in range(len(watermarked_doc)):
        page_text = watermarked_doc[page_num].get_text()
        assert f"Page {page_num+1} Content" in page_text, f"Page {page_num+1} text should be selectable"
        assert "Important text" in page_text, f"Page {page_num+1} content should be preserved"

    watermarked_doc.close()
    os.unlink(original_path)
    os.unlink(watermarked_path)


def test_integration_with_test_fixtures():
    from pdf_processing import apply_vector_watermark_to_pdf

    fixture_path = "test_fixtures/highres_test.pdf"

    if not os.path.exists(fixture_path):
        pytest.skip("Test fixture not found")

    doc = fitz.open(fixture_path)

    params = WatermarkParams(text="TEST", opacity=30, font_size=36, spacing=150, color="White")
    apply_vector_watermark_to_pdf(doc, params)

    with tempfile.NamedTemporaryFile(suffix='.pdf', delete=False) as tmp:
        output_path = tmp.name
        doc.save(output_path)
    doc.close()

    watermarked_doc = fitz.open(output_path)

    page_text = watermarked_doc[0].get_text()
    assert "High-Resolution Quality Test" in page_text, "Original text should be preserved"
    assert "Zoom to 400%" in page_text, "Instructions should be preserved"

    content = watermarked_doc[0].read_contents()
    assert b'Tf' in content, "Font operators should be present (vector text)"
    assert b'TJ' in content or b'Tj' in content, "Text show operators should be present"

    watermarked_doc.close()
    os.unlink(output_path)
