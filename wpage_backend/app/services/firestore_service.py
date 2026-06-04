from datetime import datetime, timezone

from fastapi import HTTPException

from app.models.page import PageData, PageResponse
from app.utils.config import PUBLIC_BASE_URL, get_firestore_client
from app.utils.page_normalizer import normalize_page_dict


def _parse_page(data: dict) -> PageData:
    return PageData.model_validate(normalize_page_dict(data))


def _find_page_doc(alias: str):
    db = get_firestore_client()
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Firebase credentials not configured",
        )

    docs = db.collection("pages").where("alias", "==", alias).limit(1).stream()
    for doc in docs:
        return doc.reference, _parse_page(doc.to_dict())
    return None


def save_page(page: PageData) -> str:
    db = get_firestore_client()
    if db is None:
        raise HTTPException(
            status_code=503,
            detail="Firebase credentials not configured",
        )

    try:
        _, doc_ref = db.collection("pages").add(page.dump())
        return doc_ref.id
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to save page to Firestore: {exc}",
        ) from exc


def get_page_by_alias(alias: str) -> PageData | None:
    result = _find_page_doc(alias)
    if result is None:
        return None
    _, page = result
    return page


def update_page(alias: str, page: PageData) -> dict:
    result = _find_page_doc(alias)
    if result is None:
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")

    doc_ref, existing = result
    updated_at = datetime.now(timezone.utc).isoformat()
    data = page.dump()
    data["updatedAt"] = updated_at
    data["published"] = existing.published
    if existing.publishedAt:
        data["publishedAt"] = existing.publishedAt

    try:
        doc_ref.set(data)
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to update page in Firestore: {exc}",
        ) from exc

    return data


def publish_page(alias: str) -> dict:
    result = _find_page_doc(alias)
    if result is None:
        raise HTTPException(status_code=404, detail=f"Page not found for alias: {alias}")

    doc_ref, page = result
    published_at = datetime.now(timezone.utc).isoformat()
    data = page.dump()
    data["published"] = True
    data["publishedAt"] = published_at

    try:
        doc_ref.set(data)
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to publish page: {exc}",
        ) from exc

    return {
        "alias": alias,
        "publicUrl": f"{PUBLIC_BASE_URL}/{alias}",
        "published": True,
        "publishedAt": published_at,
    }


def page_to_response(page: PageData) -> PageResponse:
    return PageResponse.model_validate(page.model_dump())
