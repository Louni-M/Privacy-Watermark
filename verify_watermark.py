from main import apply_watermark
from PIL import Image
import io

def verify():
    # Create a test image
    img = Image.new("RGB", (800, 600), color="skyblue")
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    original_bytes = img_byte_arr.getvalue()
    
    # Apply watermark
    watermarked_bytes = apply_watermark(original_bytes, "CONFIDENTIEL", opacity=40, font_size=40, spacing=200)
    
    # Save result
    with open("watermark_verification.jpg", "wb") as f:
        f.write(watermarked_bytes)
    
    print("Verification image saved: watermark_verification.jpg")

if __name__ == "__main__":
    verify()
