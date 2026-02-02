
import fitz
import time
import pytest
from pdf_processing import apply_vector_watermark_to_pdf

def test_performance_10_pages(tmp_path):
    # Create 10-page PDF
    doc = fitz.open()
    for i in range(10):
        page = doc.new_page()
        page.insert_text((100, 100), f"Page {i+1}")
    
    start_time = time.time()
    apply_vector_watermark_to_pdf(
        doc=doc,
        text="PERFORMANCE TEST",
        opacity=30,
        font_size=36,
        spacing=150,
        color="Noir"
    )
    end_time = time.time()
    duration = end_time - start_time
    
    print(f"\nTime to watermark 10 pages: {duration:.4f}s")
    
    # Requirement: < 5 seconds
    assert duration < 5.0

if __name__ == "__main__":
    # Allow running as script
    test_performance_10_pages(None)
