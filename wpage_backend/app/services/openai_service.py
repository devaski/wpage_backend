import json

from fastapi import HTTPException
from openai import APIError
from pydantic import ValidationError

from app.models.page import GeneratePageRequest, PageData
from app.utils.alias_utils import derive_alias
from app.utils.config import openai_client
from app.utils.page_normalizer import normalize_page_dict

PAGE_JSON_SCHEMA = """
{
  "identity": "user@example.com",
  "alias": "user",
  "title": "Page title",
  "description": "Short page description",
  "sections": [
    {"id": "title-1", "type": "title", "order": 0, "content": {"heading": "...", "subheading": "..."}},
    {"id": "about-1", "type": "about", "order": 1, "content": {"text": "..."}},
    {"id": "contact-1", "type": "contact", "order": 2, "content": {"email": "user@example.com"}}
  ]
}
"""


def generate_page_data(request: GeneratePageRequest) -> PageData:
    if not openai_client:
        raise HTTPException(status_code=503, detail="OpenAI API key not configured")

    alias = request.alias or derive_alias(request.identity)
    location_line = ""
    if request.geoLocationEnabled and request.location:
        location_line = f"Location: {request.location}\n"

    try:
        response = openai_client.chat.completions.create(
            model="gpt-4o-mini",
            response_format={"type": "json_object"},
            messages=[
                {
                    "role": "system",
                    "content": (
                        "You generate structured WPage JSON for personal and business web pages. "
                        "Return only valid JSON matching the requested schema."
                    ),
                },
                {
                    "role": "user",
                    "content": (
                        f"Create a WPage for:\n"
                        f"Identity: {request.identity}\n"
                        f"WPage Title: {request.title}\n"
                        f"Purpose: {request.purpose}\n"
                        f"{location_line}"
                        f"Description: {request.description}\n\n"
                        f"Use the WPage Title as the page title and title section heading.\n"
                        f"Return JSON exactly in this shape:\n{PAGE_JSON_SCHEMA}\n\n"
                        "Include 3-6 sections. "
                        "Allowed section types: title, about, services, table, image, video, links, "
                        "contact, call_to_action, footer. "
                        "Each section must include id, type, order, and content."
                    ),
                },
            ],
        )
    except APIError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc

    try:
        page_data = json.loads(response.choices[0].message.content)
        page_data["identity"] = request.identity
        page_data["alias"] = alias
        page_data["purpose"] = request.purpose
        page_data["title"] = request.title
        page_data["description"] = request.description
        page_data["geoLocationEnabled"] = request.geoLocationEnabled
        if request.location:
            page_data["location"] = request.location
        page_data["published"] = False
        page_data = normalize_page_dict(page_data)
        return PageData.model_validate(page_data)
    except (json.JSONDecodeError, ValidationError) as exc:
        raise HTTPException(
            status_code=502,
            detail=f"OpenAI returned invalid page JSON: {exc}",
        ) from exc
