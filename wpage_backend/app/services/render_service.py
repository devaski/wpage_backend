import html
import json
import re
from typing import Any
from urllib.parse import urlparse

from app.models.page import PageData, PageSection
from app.utils.section_utils import sort_sections_by_order

SUPPORTED_SECTION_TYPES = frozenset({
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
    # legacy aliases for older stored pages
    "hero",
    "text",
})

PAGE_STYLES = """
:root {
  --color-bg: #f8fafc;
  --color-surface: #ffffff;
  --color-text: #0f172a;
  --color-muted: #64748b;
  --color-border: #e2e8f0;
  --color-primary: #2563eb;
  --color-primary-hover: #1d4ed8;
  --color-hero-bg: linear-gradient(135deg, #1e3a8a 0%, #2563eb 100%);
  --radius: 12px;
  --shadow: 0 1px 3px rgba(15, 23, 42, 0.08), 0 4px 12px rgba(15, 23, 42, 0.04);
  --max-width: 960px;
  --font-sans: system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
}

*, *::before, *::after { box-sizing: border-box; }

html { scroll-behavior: smooth; }

body {
  font-family: var(--font-sans);
  line-height: 1.6;
  margin: 0;
  color: var(--color-text);
  background: var(--color-bg);
  -webkit-font-smoothing: antialiased;
}

img, video, iframe { max-width: 100%; height: auto; display: block; }

a { color: var(--color-primary); text-decoration: none; }
a:hover { text-decoration: underline; }

.page { min-height: 100vh; display: flex; flex-direction: column; }

.page-main {
  flex: 1;
  width: 100%;
  max-width: var(--max-width);
  margin: 0 auto;
  padding: 0 1.25rem 3rem;
}

/* Hero */
.block-hero {
  background: var(--color-hero-bg);
  color: #fff;
  text-align: center;
  padding: 4rem 1.5rem;
  margin: 0 -1.25rem 2rem;
  border-radius: 0 0 var(--radius) var(--radius);
}
.block-hero h1 {
  font-size: clamp(1.75rem, 5vw, 2.75rem);
  font-weight: 700;
  margin: 0 0 0.75rem;
  line-height: 1.2;
  letter-spacing: -0.02em;
}
.block-hero .subtitle {
  font-size: clamp(1rem, 2.5vw, 1.25rem);
  opacity: 0.92;
  margin: 0;
  max-width: 36rem;
  margin-inline: auto;
}

/* Card blocks */
.block-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
  padding: 1.75rem;
  margin-bottom: 1.25rem;
  box-shadow: var(--shadow);
}
.block-card h2 {
  font-size: 1.375rem;
  font-weight: 600;
  margin: 0 0 1rem;
  color: var(--color-text);
  letter-spacing: -0.01em;
}
.block-card p { margin: 0 0 0.75rem; color: var(--color-muted); }
.block-card p:last-child { margin-bottom: 0; }

/* Services grid */
.services-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1rem;
  list-style: none;
  padding: 0;
  margin: 0;
}
.services-grid li {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: 8px;
  padding: 1rem 1.25rem;
  font-size: 0.9375rem;
  color: var(--color-text);
}

/* Table */
.table-wrap { overflow-x: auto; -webkit-overflow-scrolling: touch; margin-top: 0.5rem; }
.block-table table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.9375rem;
}
.block-table th,
.block-table td {
  padding: 0.75rem 1rem;
  text-align: left;
  border-bottom: 1px solid var(--color-border);
}
.block-table th {
  background: var(--color-bg);
  font-weight: 600;
  color: var(--color-text);
}
.block-table tr:last-child td { border-bottom: none; }

/* Image */
.block-image figure { margin: 0; }
.block-image img {
  width: 100%;
  border-radius: 8px;
  border: 1px solid var(--color-border);
}
.block-image figcaption {
  margin-top: 0.75rem;
  font-size: 0.875rem;
  color: var(--color-muted);
  text-align: center;
}

/* Video */
.block-video .video-wrap {
  position: relative;
  padding-bottom: 56.25%;
  height: 0;
  overflow: hidden;
  border-radius: 8px;
  background: #000;
}
.block-video iframe,
.block-video video {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  border: 0;
  border-radius: 8px;
}

/* Links */
.links-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.links-list a {
  display: inline-flex;
  align-items: center;
  padding: 0.625rem 0;
  font-weight: 500;
  border-bottom: 1px solid var(--color-border);
}
.links-list li:last-child a { border-bottom: none; }

/* Contact */
.contact-details { display: flex; flex-direction: column; gap: 0.5rem; }
.contact-details p { margin: 0; }

/* CTA */
.block-cta {
  text-align: center;
  background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
  border-color: #bfdbfe;
}
.block-cta h2 { margin-bottom: 0.5rem; }
.cta-button {
  display: inline-block;
  margin-top: 1rem;
  padding: 0.875rem 1.75rem;
  background: var(--color-primary);
  color: #fff !important;
  text-decoration: none !important;
  border-radius: 8px;
  font-weight: 600;
  font-size: 1rem;
  transition: background 0.2s;
}
.cta-button:hover { background: var(--color-primary-hover); text-decoration: none !important; }

/* Footer */
.block-footer {
  margin-top: 2rem;
  padding: 2rem 1.25rem;
  margin-inline: -1.25rem;
  background: var(--color-text);
  color: #94a3b8;
  text-align: center;
  font-size: 0.875rem;
  border-radius: var(--radius) var(--radius) 0 0;
}
.block-footer p { margin: 0; color: #94a3b8; }
.block-footer a { color: #cbd5e1; }

@media (min-width: 768px) {
  .page-main { padding: 0 2rem 4rem; }
  .block-hero { margin-inline: -2rem; padding: 5rem 2rem; }
  .block-footer { margin-inline: -2rem; padding: 2.5rem 2rem; }
}
"""


def _esc(value: Any) -> str:
    return html.escape(str(value)) if value is not None else ""


def _format_list_item(item: Any) -> str:
    if isinstance(item, dict):
        label = (
            item.get("title")
            or item.get("name")
            or item.get("label")
            or item.get("text")
        )
        return _esc(label) if label is not None else _esc(item)
    return _esc(item)


def _content_dict(section: PageSection) -> dict[str, Any]:
    if isinstance(section.content, dict):
        return section.content
    if isinstance(section.content, str):
        return {"text": section.content}
    if isinstance(section.content, list):
        return {"items": section.content}
    return {}


def _heading(content: dict[str, Any], default: str) -> str:
    return _esc(content.get("heading") or default)


def _text_to_html(text: str) -> str:
    return _esc(text).replace("\n", "<br>")


def _list_items(content: dict[str, Any], *keys: str) -> list[Any]:
    for key in keys:
        value = content.get(key)
        if isinstance(value, list):
            return value
    return []


def _safe_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme in ("http", "https", "mailto"):
        return _esc(url)
    return "#"


def _youtube_embed(url: str) -> str | None:
    patterns = [
        r"(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/embed/)([\w-]{11})",
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            video_id = match.group(1)
            return f"https://www.youtube.com/embed/{video_id}"
    return None


def _render_hero(block: PageSection, content: dict[str, Any]) -> str:
    title = _esc(content.get("heading") or content.get("title") or "")
    subtitle = _esc(content.get("subheading", ""))
    subtitle_html = f'<p class="subtitle">{subtitle}</p>' if subtitle else ""
    return (
        f'<section id="{_esc(block.id)}" class="block-hero" aria-label="Hero">'
        f"<h1>{title}</h1>{subtitle_html}</section>"
    )


def _render_text(block: PageSection, content: dict[str, Any]) -> str:
    heading = content.get("heading")
    heading_html = f"<h2>{_esc(heading)}</h2>" if heading else ""
    text = _text_to_html(str(content.get("text", "")))
    return (
        f'<section id="{_esc(block.id)}" class="block-card block-text">'
        f"{heading_html}<p>{text}</p></section>"
    )


def _render_services(block: PageSection, content: dict[str, Any]) -> str:
    heading = _heading(content, "Services")
    items = _list_items(content, "items", "services")
    if items:
        items_html = "".join(f"<li>{_format_list_item(item)}</li>" for item in items)
        body = f'<ul class="services-grid">{items_html}</ul>'
    else:
        body = f"<p>{_text_to_html(str(content.get('text', '')))}</p>"
    return (
        f'<section id="{_esc(block.id)}" class="block-card block-services">'
        f"<h2>{heading}</h2>{body}</section>"
    )


def _render_table(block: PageSection, content: dict[str, Any]) -> str:
    heading = _heading(content, "Table")
    headers = content.get("headers") or content.get("columns") or []
    rows = content.get("rows") or []

    if not headers and rows and isinstance(rows[0], list):
        headers = [f"Column {i + 1}" for i in range(len(rows[0]))]

    header_html = ""
    if headers:
        header_html = "<thead><tr>" + "".join(
            f"<th>{_esc(h)}</th>" for h in headers
        ) + "</tr></thead>"

    body_rows = ""
    for row in rows:
        if isinstance(row, list):
            body_rows += "<tr>" + "".join(f"<td>{_esc(cell)}</td>" for cell in row) + "</tr>"
        elif isinstance(row, dict):
            cells = [row.get(h, "") for h in headers] if headers else list(row.values())
            body_rows += "<tr>" + "".join(f"<td>{_esc(cell)}</td>" for cell in cells) + "</tr>"

    table_html = f'<div class="table-wrap"><table>{header_html}<tbody>{body_rows}</tbody></table></div>'
    return (
        f'<section id="{_esc(block.id)}" class="block-card block-table">'
        f"<h2>{heading}</h2>{table_html}</section>"
    )


def _render_image(block: PageSection, content: dict[str, Any]) -> str:
    src = content.get("src") or content.get("url") or content.get("image") or ""
    alt = _esc(content.get("alt", content.get("caption", "")))
    caption = content.get("caption") or content.get("title")
    caption_html = f"<figcaption>{_esc(caption)}</figcaption>" if caption else ""
    if not src:
        return (
            f'<section id="{_esc(block.id)}" class="block-card block-image">'
            f"<p>{_text_to_html(str(content.get('text', 'Image unavailable')))}</p></section>"
        )
    return (
        f'<section id="{_esc(block.id)}" class="block-card block-image">'
        f'<figure><img src="{_safe_url(str(src))}" alt="{alt}" loading="lazy">'
        f"{caption_html}</figure></section>"
    )


def _render_video(block: PageSection, content: dict[str, Any]) -> str:
    url = str(content.get("url") or content.get("src") or content.get("video") or "")
    title = _esc(content.get("title", "Video"))
    heading = content.get("heading")
    heading_html = f"<h2>{_esc(heading)}</h2>" if heading else ""

    embed_url = _youtube_embed(url)
    if embed_url:
        media = (
            f'<div class="video-wrap"><iframe src="{_esc(embed_url)}" '
            f'title="{title}" allowfullscreen loading="lazy"></iframe></div>'
        )
    elif url:
        media = (
            f'<div class="video-wrap"><video src="{_safe_url(url)}" controls '
            f'preload="metadata"></video></div>'
        )
    else:
        media = f"<p>{_text_to_html(str(content.get('text', 'Video unavailable')))}</p>"

    return (
        f'<section id="{_esc(block.id)}" class="block-card block-video">'
        f"{heading_html}{media}</section>"
    )


def _render_links(block: PageSection, content: dict[str, Any]) -> str:
    heading = _heading(content, "Links")
    links = content.get("links") or content.get("items") or []
    if isinstance(links, dict):
        links = [{"label": k, "url": v} for k, v in links.items()]

    links_html = ""
    for link in links:
        if isinstance(link, dict):
            label = _esc(link.get("label") or link.get("title") or link.get("text", "Link"))
            url = _safe_url(str(link.get("url") or link.get("href", "#")))
        else:
            label = _esc(link)
            url = "#"
        links_html += f'<li><a href="{url}" target="_blank" rel="noopener noreferrer">{label}</a></li>'

    return (
        f'<section id="{_esc(block.id)}" class="block-card block-links">'
        f"<h2>{heading}</h2><ul class=\"links-list\">{links_html}</ul></section>"
    )


def _render_contact(block: PageSection, content: dict[str, Any]) -> str:
    heading = _heading(content, "Contact")
    parts = []
    if content.get("email"):
        email = _esc(content["email"])
        parts.append(f'<p>Email: <a href="mailto:{email}">{email}</a></p>')
    if content.get("phone"):
        parts.append(f"<p>Phone: {_esc(content['phone'])}</p>")
    if content.get("address"):
        parts.append(f"<p>{_text_to_html(str(content['address']))}</p>")
    if content.get("text"):
        parts.append(f"<p>{_text_to_html(str(content['text']))}</p>")
    body = "".join(parts) or "<p>Contact information not available.</p>"
    return (
        f'<section id="{_esc(block.id)}" class="block-card block-contact">'
        f"<h2>{heading}</h2><div class=\"contact-details\">{body}</div></section>"
    )


def _render_call_to_action(block: PageSection, content: dict[str, Any]) -> str:
    heading = _heading(content, "Get in touch")
    text = _text_to_html(str(content.get("text", "")))
    button_text = content.get("button_text") or content.get("cta_text")
    button_url = content.get("button_url") or content.get("cta_url") or "#contact"
    button_html = ""
    if button_text:
        button_html = (
            f'<a class="cta-button" href="{_safe_url(str(button_url))}">'
            f"{_esc(button_text)}</a>"
        )
    return (
        f'<section id="{_esc(block.id)}" class="block-card block-cta">'
        f"<h2>{heading}</h2><p>{text}</p>{button_html}</section>"
    )


def _render_footer(block: PageSection, content: dict[str, Any]) -> str:
    text = _text_to_html(str(content.get("text", "")))
    links = content.get("links") or []
    links_html = ""
    if isinstance(links, list) and links:
        link_items = []
        for link in links:
            if isinstance(link, dict):
                label = _esc(link.get("label") or link.get("title", "Link"))
                url = _safe_url(str(link.get("url") or link.get("href", "#")))
                link_items.append(f'<a href="{url}">{label}</a>')
        if link_items:
            links_html = "<p>" + " · ".join(link_items) + "</p>"
    return (
        f'<footer id="{_esc(block.id)}" class="block-footer">'
        f"<p>{text}</p>{links_html}</footer>"
    )


_SECTION_RENDERERS = {
    "title": _render_hero,
    "hero": _render_hero,
    "about": _render_text,
    "text": _render_text,
    "services": _render_services,
    "table": _render_table,
    "image": _render_image,
    "video": _render_video,
    "links": _render_links,
    "contact": _render_contact,
    "call_to_action": _render_call_to_action,
    "footer": _render_footer,
}


def render_public_section(section: PageSection) -> str:
    if section.type not in SUPPORTED_SECTION_TYPES:
        return ""
    content = _content_dict(section)
    renderer = _SECTION_RENDERERS.get(section.type)
    if renderer is None:
        return ""
    return renderer(section, content)


def render_public_page_html(page: PageData) -> str:
    title = _esc(page.title)
    description = _esc(page.description)
    ordered_sections = sort_sections_by_order(page.sections)
    sections_html = "\n".join(
        render_public_section(section)
        for section in ordered_sections
        if section.type in SUPPORTED_SECTION_TYPES
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <meta name="description" content="{description}">
  <style>{PAGE_STYLES}</style>
</head>
<body>
  <div class="page">
    <main class="page-main">
      {sections_html}
    </main>
  </div>
</body>
</html>"""


def _block_content_text(content: dict[str, Any] | str | None) -> str:
    if content is None:
        return ""
    if isinstance(content, str):
        return content
    if "text" in content:
        return str(content["text"])
    if "heading" in content:
        parts = [str(content["heading"])]
        if content.get("subheading"):
            parts.append(str(content["subheading"]))
        return "\n".join(parts)
    if "email" in content:
        return str(content["email"])
    return json.dumps(content, indent=2)


def _render_section(section: PageSection) -> str:
    heading = html.escape(section.type.title())
    body = html.escape(_block_content_text(section.content)).replace("\n", "<br>")

    if section.type in {"hero", "title"}:
        content = section.content if isinstance(section.content, dict) else {}
        title_text = html.escape(str(content.get("heading", section.type.title())))
        subtitle = html.escape(str(content.get("subheading", "")))
        subtitle_html = f"<p>{subtitle}</p>" if subtitle else ""
        return f'<section class="hero"><h1>{title_text}</h1>{subtitle_html}</section>'

    if section.type == "contact" and isinstance(section.content, dict) and section.content.get("email"):
        email = html.escape(str(section.content["email"]))
        return f'<section class="block contact"><h2>{heading}</h2><p><a href="mailto:{email}">{email}</a></p></section>'

    return f'<section class="block {html.escape(section.type)}"><h2>{heading}</h2><p>{body}</p></section>'


def render_page_html(page: PageData) -> str:
    title = html.escape(page.title)
    description = html.escape(page.description)
    sections_html = "\n".join(_render_section(section) for section in page.sections)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title}</title>
  <meta name="description" content="{description}">
  <style>
    body {{ font-family: system-ui, sans-serif; line-height: 1.6; margin: 0; color: #1a1a1a; background: #fafafa; }}
    main {{ max-width: 720px; margin: 0 auto; padding: 2rem 1rem; }}
    .hero {{ padding: 3rem 0 2rem; border-bottom: 1px solid #e5e5e5; margin-bottom: 2rem; }}
    .hero h1 {{ font-size: 2.5rem; margin: 0 0 0.5rem; }}
    .hero p {{ color: #555; font-size: 1.125rem; margin: 0; }}
    .block {{ background: #fff; border: 1px solid #e5e5e5; border-radius: 12px; padding: 1.5rem; margin-bottom: 1rem; }}
    .block h2 {{ margin: 0 0 0.75rem; font-size: 1.25rem; }}
    .block p {{ margin: 0; color: #333; }}
    a {{ color: #2563eb; }}
  </style>
</head>
<body>
  <main>
    {sections_html}
  </main>
</body>
</html>"""
