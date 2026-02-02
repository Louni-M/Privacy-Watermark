import fitz
from PIL import Image
import io
import os

def load_pdf(file_path):
    """
    Charge un fichier PDF et retourne le document et le nombre de pages.
    Lève une exception si le PDF est protégé ou invalide.
    """
    try:
        doc = fitz.open(file_path)
        if doc.is_encrypted:
             raise Exception("Ce PDF est protégé par mot de passe et ne peut pas être ouvert.")
        if doc.page_count == 0:
             raise Exception("Impossible de lire ce fichier PDF (aucune page).")
        return doc, doc.page_count
    except fitz.FileDataError:
        raise Exception("Impossible de lire ce fichier PDF.")
    except Exception as e:
        if "protégé" in str(e):
            raise e
        raise Exception(f"Erreur lors du chargement du PDF : {e}")

def pdf_page_to_image(doc, page_num):
    """
    Convertit une page PDF en image PIL pour la prévisualisation.
    """
    page = doc.load_page(page_num)
    pix = page.get_pixmap(alpha=True)
    img = Image.frombytes("RGBA", [pix.width, pix.height], pix.samples)
    return img

def apply_watermark_to_pdf(doc, watermark_params):
    """
    Applique un filigrane sur toutes les pages du document PDF.
    """
    # Placeholder for Task 2.6
    pass
