from datetime import datetime
from typing import Any

LEGACY_SECTION_TYPE_MAP = {
    "hero": "title",
    "text": "about",
}

ALLOWED_SECTION_TYPES = frozenset({
    "title",
    "about",
    "services",
    "table",
    "image",
    "video",
    "links",
    "contact",
    "call_to_action",
    "footer",
})


def _coerce_timestamp(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value
    if isinstance(value, datetime):
        return value.isoformat()
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return str(value)


def _normalize_section(section: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(section)
    section_type = normalized.get("type")
    if section_type in LEGACY_SECTION_TYPE_MAP:
        normalized["type"] = LEGACY_SECTION_TYPE_MAP[section_type]
    elif section_type not in ALLOWED_SECTION_TYPES:
        normalized["type"] = "about"

    order = normalized.get("order")
    if order is not None:
        try:
            normalized["order"] = int(order)
        except (TypeError, ValueError):
            normalized["order"] = None

    content = normalized.get("content")
    if content is None:
        normalized["content"] = {}
    elif isinstance(content, list):
        normalized["content"] = {"items": content}

    normalized.setdefault("id", normalized.get("type", "section"))
    return normalized


def normalize_page_dict(data: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(data)

    if "sections" not in normalized and "blocks" in normalized:
        normalized["sections"] = [
            _normalize_section(section) for section in normalized.pop("blocks")
        ]
    elif "sections" in normalized:
        normalized["sections"] = [
            _normalize_section(section) for section in normalized["sections"]
        ]

    normalized.setdefault("purpose", "")
    normalized.setdefault("published", False)
    normalized["updatedAt"] = _coerce_timestamp(normalized.get("updatedAt"))
    normalized["publishedAt"] = _coerce_timestamp(normalized.get("publishedAt"))
    return normalized
