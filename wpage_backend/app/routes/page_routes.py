from fastapi import APIRouter, Query, Request
from fastapi.responses import HTMLResponse, Response

from app.controllers.page_controller import (
    generate_page_controller,
    get_page_controller,
    publish_page_controller,
    qr_image_controller,
    qr_page_controller,
    render_page_controller,
    render_preview_controller,
    update_page_controller,
)
from app.models.page import (
    GeneratePageRequest,
    GeneratePageResponse,
    PublishResponse,
    QrRequest,
    QrResponse,
    UpdatePageRequest,
)

router = APIRouter()


@router.get("/")
def root():
    return {"message": "Wpage Backend is running"}


@router.get("/health")
def health():
    return {"status": "ok"}


@router.post(
    "/generate-page",
    response_model=GeneratePageResponse,
    response_model_exclude_none=True,
)
def generate_page(request: GeneratePageRequest) -> GeneratePageResponse:
    return generate_page_controller(request)


@router.get("/page/{alias}")
def get_page(alias: str, request: Request):
    return get_page_controller(alias, request)


@router.put("/page/{alias}")
def update_page(alias: str, request: UpdatePageRequest):
    return update_page_controller(alias, request)


@router.get("/render/{alias}", response_class=HTMLResponse)
def render_page(alias: str) -> HTMLResponse:
    return render_page_controller(alias)


@router.post("/render/preview", response_class=HTMLResponse)
def render_preview(request: UpdatePageRequest) -> HTMLResponse:
    return render_preview_controller(request)


@router.post("/page/{alias}/publish", response_model=PublishResponse)
def publish_page(alias: str) -> PublishResponse:
    return publish_page_controller(alias)


@router.post("/page/{alias}/qr", response_model=QrResponse)
def create_qr(alias: str, request: QrRequest | None = None) -> QrResponse:
    return qr_page_controller(alias, request)


@router.get("/qr/{alias}.png")
def get_qr_image(alias: str, size: int = Query(default=300, ge=100, le=1000)) -> Response:
    return qr_image_controller(alias, size)
