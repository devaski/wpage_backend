from fastapi import HTTPException, Request
from fastapi.responses import HTMLResponse, Response

from app.models.page import (
    GeneratePageRequest,
    GeneratePageResponse,
    PageData,
    PageResponse,
    PublishResponse,
    QrRequest,
    QrResponse,
    UpdatePageRequest,
)
from app.services.firestore_service import (
    get_page_by_alias,
    page_to_response,
    publish_page,
    save_page,
    update_page,
)
from app.services.openai_service import generate_page_data
from app.services.qr_service import create_qr_response, generate_qr_png
from app.services.render_service import render_page_html, render_public_page_html
from app.utils.alias_utils import is_reserved_alias
from app.utils.config import PUBLIC_BASE_URL
from app.utils.page_normalizer import normalize_page_dict


def generate_page_controller(request: GeneratePageRequest) -> GeneratePageResponse:
    page = generate_page_data(request)
    page_id = save_page(page)
    public_url = f"{PUBLIC_BASE_URL}/{page.alias}"
    return GeneratePageResponse(
        pageId=page_id,
        publicUrl=public_url,
        page=page_to_response(page),
    )


def get_page_controller(alias: str, request: Request):
    page = get_page_by_alias(alias)
    if not page:
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")

    accept = request.headers.get("accept", "")
    if "text/html" in accept and "application/json" not in accept:
        return HTMLResponse(render_page_html(page))

    return page_to_response(page).dump()


def update_page_controller(alias: str, request: UpdatePageRequest) -> dict:
    if request.alias != alias:
        raise HTTPException(
            status_code=400,
            detail=f"Alias in body ({request.alias}) does not match URL ({alias})",
        )

    page = PageData.model_validate(request.model_dump())
    return update_page(alias, page)


def render_page_controller(alias: str) -> HTMLResponse:
    page = get_page_by_alias(alias)
    if not page:
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")
    try:
        return HTMLResponse(render_public_page_html(page))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to render page: {exc}") from exc


def public_alias_controller(alias: str) -> HTMLResponse:
    if is_reserved_alias(alias):
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")
    return render_page_controller(alias)


def render_preview_controller(request: UpdatePageRequest) -> HTMLResponse:
    page = PageData.model_validate(
        normalize_page_dict({**request.model_dump(), "published": False})
    )
    try:
        return HTMLResponse(render_public_page_html(page))
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Failed to render preview: {exc}") from exc


def publish_page_controller(alias: str) -> PublishResponse:
    result = publish_page(alias)
    return PublishResponse.model_validate(result)


def qr_page_controller(alias: str, request: QrRequest | None = None) -> QrResponse:
    size = request.size if request else 300
    result = create_qr_response(alias, size)
    return QrResponse.model_validate(result)


def qr_image_controller(alias: str, size: int = 300) -> Response:
    page = get_page_by_alias(alias)
    if not page:
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")

    png_bytes = generate_qr_png(alias, size)
    return Response(content=png_bytes, media_type="image/png")
