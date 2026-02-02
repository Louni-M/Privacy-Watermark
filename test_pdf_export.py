import pytest
import os
import fitz
from pdf_processing import load_pdf, apply_watermark_to_pdf, save_watermarked_pdf, save_pdf_as_images

def test_save_watermarked_pdf(sample_pdf, tmp_path):
    doc, _ = load_pdf(sample_pdf)
    params = {"text": "TEST EXPORT", "opacity": 30, "font_size": 36, "spacing": 150}
    apply_watermark_to_pdf(doc, params)
    
    output_file = tmp_path / "exported.pdf"
    save_watermarked_pdf(doc, str(output_file))
    
    assert output_file.exists()
    # Verify it's a valid PDF
    new_doc = fitz.open(str(output_file))
    assert new_doc.page_count == doc.page_count
    new_doc.close()
    doc.close()

def test_save_pdf_as_images(sample_pdf, tmp_path):
    doc, _ = load_pdf(sample_pdf)
    params = {"text": "TEST IMAGES", "opacity": 30, "font_size": 36, "spacing": 150}
    apply_watermark_to_pdf(doc, params)
    
    output_dir = tmp_path / "export_images"
    output_dir.mkdir()
    base_name = "test_doc"
    
    save_pdf_as_images(doc, str(output_dir), base_name)
    
    # Check if files exist
    for i in range(doc.page_count):
        expected_file = output_dir / f"{base_name}_page_{i+1:03d}.jpg"
        assert expected_file.exists()
    
    doc.close()
