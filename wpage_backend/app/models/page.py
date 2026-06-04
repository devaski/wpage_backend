from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field

SectionType = Literal[
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
]


class WPageModel(BaseModel):
    model_config = ConfigDict(extra="ignore")

    def dump(self) -> dict[str, Any]:
        return self.model_dump(exclude_none=True)


class GeneratePageRequest(WPageModel):
    identity: str
    title: str
    description: str
    geoLocationEnabled: bool = False
    location: str | None = None
    alias: str | None = None
    purpose: str = "General"


class PageSection(WPageModel):
    id: str
    type: SectionType
    order: int | None = None
    content: dict[str, Any] | str | list[Any]


class PageData(WPageModel):
    identity: str
    alias: str
    purpose: str = ""
    title: str
    description: str
    sections: list[PageSection] = Field(default_factory=list)
    published: bool = False
    geoLocationEnabled: bool = False
    location: str | None = None
    updatedAt: str | None = None
    publishedAt: str | None = None


class PageResponse(WPageModel):
    identity: str
    alias: str
    purpose: str
    title: str
    description: str
    sections: list[PageSection]
    published: bool = False
    geoLocationEnabled: bool = False
    location: str | None = None
    updatedAt: str | None = None
    publishedAt: str | None = None


class UpdatePageRequest(WPageModel):
    identity: str
    alias: str
    purpose: str
    title: str
    description: str
    sections: list[PageSection]


class GeneratePageResponse(WPageModel):
    pageId: str
    publicUrl: str
    page: PageResponse


class PublishResponse(WPageModel):
    alias: str
    publicUrl: str
    published: bool
    publishedAt: str


class QrRequest(WPageModel):
    size: int = 300


class QrResponse(WPageModel):
    alias: str
    publicUrl: str
    qrCodeUrl: str
