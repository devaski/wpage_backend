import io

import qrcode
from fastapi import HTTPException

from app.services.firestore_service import get_page_by_alias
from app.utils.config import API_BASE_URL, PUBLIC_BASE_URL


def build_qr_code_url(alias: str, size: int = 300) -> str:
    return f"{API_BASE_URL}/qr/{alias}.png?size={size}"


def generate_qr_png(alias: str, size: int = 300) -> bytes:
    public_url = f"{PUBLIC_BASE_URL}/{alias}"
    qr = qrcode.QRCode(box_size=10, border=2)
    qr.add_data(public_url)
    qr.make(fit=True)
    image = qr.make_image(fill_color="black", back_color="white")
    image = image.resize((size, size))

    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def create_qr_response(alias: str, size: int = 300) -> dict:
    page = get_page_by_alias(alias)
    if not page:
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")
    if not page.published:
        raise HTTPException(status_code=400, detail="Page is not published yet")

    try:
        qr_code_url = build_qr_code_url(alias, size)
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to generate QR code: {exc}",
        ) from exc

    return {
        "alias": alias,
        "publicUrl": f"{PUBLIC_BASE_URL}/{alias}",
        "qrCodeUrl": qr_code_url,
    }
