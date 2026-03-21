
import fitz
import time
import pytest
from pdf_processing import apply_vector_watermark_to_pdf
from watermark import WatermarkParams

def test_performance_10_pages(tmp_path):
    doc = fitz.open()
    for i in range(10):
        page = doc.new_page()
        page.insert_text((100, 100), f"Page {i+1}")

    params = WatermarkParams(text="PERFORMANCE TEST", opacity=30, font_size=36, spacing=150, color="Black")
    start_time = time.time()
    apply_vector_watermark_to_pdf(doc, params)
    end_time = time.time()
    duration = end_time - start_time

    print(f"\nTime to watermark 10 pages: {duration:.4f}s")
    assert duration < 5.0

if __name__ == "__main__":
    test_performance_10_pages(None)
