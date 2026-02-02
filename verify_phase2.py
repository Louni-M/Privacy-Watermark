import fitz
from pdf_processing import load_pdf, apply_watermark_to_pdf
import os

def manual_verify():
    # Create a simple PDF for verification
    pdf_path = "verify_phase2.pdf"
    doc = fitz.open()
    page = doc.new_page()
    page.insert_text((72, 72), "Document de test pour Phase 2", fontsize=20)
    doc.save(pdf_path)
    doc.close()
    
    print(f"PDF de test créé : {pdf_path}")
    
    # Load and Apply Watermark
    doc, num_pages = load_pdf(pdf_path)
    params = {
        "text": "VERIFICATION PHASE 2",
        "opacity": 50,
        "font_size": 40,
        "spacing": 150
    }
    apply_watermark_to_pdf(doc, params)
    
    # Save output
    output_path = "output_phase2_verified.pdf"
    doc.save(output_path)
    doc.close()
    
    print(f"PDF filigrané sauvegardé : {output_path}")
    print("Veuillez ouvrir 'output_phase2_verified.pdf' pour vérifier le résultat.")

if __name__ == "__main__":
    manual_verify()
