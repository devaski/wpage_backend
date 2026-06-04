from typing import Any

LEGACY_SECTION_TYPE_MAP = {
    "hero": "title",
    "text": "about",
}


def _normalize_section(section: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(section)
    section_type = normalized.get("type")
    if section_type in LEGACY_SECTION_TYPE_MAP:
        normalized["type"] = LEGACY_SECTION_TYPE_MAP[section_type]
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
    return normalized
