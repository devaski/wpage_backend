# WPage API Contract

This document defines the backend API for the WPage creation experience.

WPage is designed for everyday users — not website designers. The product flow is:

**Answer simple questions → AI creates your website → you edit a few sections → publish and share.**

The Flutter/Web UI should **not** present drag-and-drop builders, block canvases, or technical layout tools. Users should feel like they are filling out a short guided form, not designing a website manually.

---

## User Journey (UI Flow)

| Step | What the user sees | Backend action |
|------|--------------------|----------------|
| 1. Pick Purpose | Choose what kind of page they need | Sent to AI on generate |
| 2. Describe Yourself / Your Business | Plain-language text box | Sent to AI on generate |
| 3. AI Generates Page | Loading / “Creating your page…” | `POST /generate-page` |
| 4. Simple Section Editing | Edit Title, About, Services, Contact, etc. | `GET /page/{alias}` + `PUT /page/{alias}` |
| 5. Preview | See how the page will look | `GET /render/{alias}` |
| 6. Publish | “Publish my page” button | `POST /page/{alias}/publish` |
| 7. Copy Public URL / QR Code | Share link or scan QR | `publicUrl` + `POST /page/{alias}/qr` |

### Purpose options (Step 1)

The UI should offer simple choices such as:

- Personal Profile
- Business Page
- Job Seeker / Resume
- Student Profile
- Service Provider
- Trader / Shop
- Professional / Consultant

These are labels for the user. The backend receives the selected value as `purpose`.

### Editable sections (Step 4)

The UI should expose friendly section names only:

- Title
- Subtitle
- About
- Services
- Contact
- Links
- Images
- Videos
- Tables

Do **not** show internal structure names (e.g. “hero”, “call_to_action”) to end users.

---

## Base URL

```
Development: http://127.0.0.1:8000
Production:  https://api.wpage.app   (example — use deployed backend URL)
```

Public page URL pattern:

```
https://wpage.app/{alias}
```

---

## Common Error Format

All error responses use JSON:

```json
{
  "detail": "Human-readable error message"
}
```

| HTTP Status | Meaning |
|-------------|---------|
| 400 | Invalid request (e.g. alias mismatch) |
| 404 | Page not found |
| 422 | Validation failed (invalid JSON / missing fields) |
| 502 | External service error (OpenAI, Firestore) |
| 503 | Service not configured (API key, Firebase) |

---

## OpenAI Usage Summary

| Endpoint | Calls OpenAI? |
|----------|---------------|
| `POST /generate-page` | **Yes** — only endpoint that calls OpenAI |
| `GET /page/{alias}` | No |
| `PUT /page/{alias}` | No |
| `GET /render/{alias}` | No |
| `POST /page/{alias}/publish` | No |
| `POST /page/{alias}/qr` | No |

All endpoints except generate work from saved Firestore JSON.

---

## 1. POST /generate-page

### Purpose

Create a complete WPage from the user’s purpose, identity, and plain-language description.  
AI builds the page structure automatically. The user does not design anything manually.

**OpenAI:** Yes

### When to call (UI)

- Step 3: after user picks a purpose and writes their description
- Show a loading state: “Creating your page…”

### Request JSON

```json
{
  "identity": "john@example.com",
  "alias": "john",
  "purpose": "Personal Profile",
  "description": "I am a software engineer based in London. I build web apps and enjoy hiking."
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `identity` | Yes | User email or unique identity |
| `alias` | Yes | Short public username for the URL (e.g. `john` → `wpage.app/john`) |
| `purpose` | Yes | Selected purpose label (see Purpose options above) |
| `description` | Yes | Plain-language description from the user |

### Response JSON

```json
{
  "pageId": "abc123xyz",
  "publicUrl": "https://wpage.app/john",
  "page": {
    "identity": "john@example.com",
    "alias": "john",
    "purpose": "Personal Profile",
    "title": "John's Profile",
    "description": "Software engineer based in London who builds web apps.",
    "published": false,
    "updatedAt": null,
    "sections": [
      {
        "id": "hero-1",
        "type": "title",
        "order": 0,
        "content": {
          "heading": "John Smith",
          "subheading": "Software Engineer · London"
        }
      },
      {
        "id": "about-1",
        "type": "about",
        "order": 1,
        "content": {
          "text": "I build web applications and enjoy hiking on weekends."
        }
      },
      {
        "id": "contact-1",
        "type": "contact",
        "order": 2,
        "content": {
          "email": "john@example.com"
        }
      }
    ]
  }
}
```

| Field | Description |
|-------|-------------|
| `pageId` | Firestore document ID |
| `publicUrl` | Shareable URL (available after publish) |
| `page` | Full page object for editing and preview |

### Error responses

| Status | Example `detail` |
|--------|------------------|
| 422 | Validation error (missing `description`, invalid JSON) |
| 502 | OpenAI error or invalid AI response |
| 502 | Failed to save page to Firestore |
| 503 | OpenAI API key not configured |

### UI usage notes

- Call once after Step 2 is complete.
- Store `pageId`, `publicUrl`, and `page.alias` locally for later steps.
- Navigate to Step 4 (section editing) using the returned `page.sections`.
- Do not ask the user to pick layout, blocks, or design templates.
- Show purpose + description as read-only summary if the user wants to review what they submitted.

---

## 2. GET /page/{alias}

### Purpose

Load a saved page for editing or preview.

**OpenAI:** No

### When to call (UI)

- Step 4: open existing page for editing
- Step 5: load page data before preview (optional if already in memory)
- App resume / return visit

### Request

```
GET /page/{alias}
Accept: application/json
```

| Path param | Description |
|------------|-------------|
| `alias` | Public username (e.g. `john`) |

### Response JSON

```json
{
  "identity": "john@example.com",
  "alias": "john",
  "purpose": "Personal Profile",
  "title": "John's Profile",
  "description": "Software engineer based in London.",
  "published": true,
  "updatedAt": "2026-06-02T08:05:03.624918+00:00",
  "sections": [
    {
      "id": "hero-1",
      "type": "title",
      "order": 0,
      "content": {
        "heading": "John Smith",
        "subheading": "Software Engineer"
      }
    }
  ]
}
```

### Error responses

| Status | Example `detail` |
|--------|------------------|
| 404 | Page not found for alias: john |
| 503 | Firebase credentials not configured |

### UI usage notes

- Use this to populate the simple section editor (Title, About, Services, etc.).
- Map each `section.type` to a friendly editor screen — never show raw JSON to the user.
- If `published` is `false`, show a “Not published yet” badge until Step 6 completes.

---

## 3. PUT /page/{alias}

### Purpose

Save edits the user made to their page sections (title, about, contact, etc.).

**OpenAI:** No

### When to call (UI)

- Step 4: when user taps “Save” or moves to Preview
- Auto-save on section blur (optional, debounced)

### Request JSON

```json
{
  "identity": "john@example.com",
  "alias": "john",
  "purpose": "Personal Profile",
  "title": "John's Profile",
  "description": "Updated short summary.",
  "sections": [
    {
      "id": "hero-1",
      "type": "title",
      "order": 0,
      "content": {
        "heading": "John Smith",
        "subheading": "Senior Software Engineer"
      }
    },
    {
      "id": "about-1",
      "type": "about",
      "order": 1,
      "content": {
        "text": "Updated about text."
      }
    }
  ]
}
```

**Rule:** `alias` in the body must match `{alias}` in the URL.

### Response JSON

Same shape as GET — includes `updatedAt` timestamp:

```json
{
  "identity": "john@example.com",
  "alias": "john",
  "purpose": "Personal Profile",
  "title": "John's Profile",
  "description": "Updated short summary.",
  "published": false,
  "updatedAt": "2026-06-02T09:15:00.000000+00:00",
  "sections": [ "..."]
}
```

### Error responses

| Status | Example `detail` |
|--------|------------------|
| 400 | Alias in body (wrong) does not match URL (john) |
| 404 | Page not found for alias: john |
| 422 | Validation error (invalid section structure) |
| 502 | Failed to update page in Firestore |

### UI usage notes

- Send the full page object after editing — not individual field patches.
- Keep section order using the `order` field so preview matches user intent.
- Confirm save with a simple toast: “Changes saved.”
- Do not regenerate content with AI on save — only persist user edits.

---

## 4. GET /render/{alias}

### Purpose

Return the public HTML version of the page for preview or live viewing.

**OpenAI:** No

### When to call (UI)

- Step 5: Preview (WebView or in-app browser)
- Public visitor viewing a published page

### Request

```
GET /render/{alias}
Accept: text/html
```

### Response

Full HTML document (`Content-Type: text/html`).

### Error responses

| Status | Example `detail` |
|--------|------------------|
| 404 | Page not found for alias: john |

### UI usage notes

- Step 5 Preview: load this URL in a WebView — “This is how your page will look.”
- Sections are rendered in `order` when present.
- No editing on this screen — read-only preview.
- After publish, the same URL is the live public page.

---

## 5. POST /page/{alias}/publish

### Purpose

Mark the page as published and make the public URL active.

**OpenAI:** No

### When to call (UI)

- Step 6: user taps “Publish my page”

### Request

```
POST /page/{alias}/publish
```

No body required.

### Response JSON

```json
{
  "alias": "john",
  "publicUrl": "https://wpage.app/john",
  "published": true,
  "publishedAt": "2026-06-02T10:00:00.000000+00:00"
}
```

### Error responses

| Status | Example `detail` |
|--------|------------------|
| 404 | Page not found for alias: john |
| 502 | Failed to publish page |

### UI usage notes

- Show confirmation: “Your page is live!”
- Display `publicUrl` with a Copy button.
- Proceed to Step 7 (QR code).
- Unpublished pages should not be promoted as shareable links in the UI.

---

## 6. POST /page/{alias}/qr

### Purpose

Generate or return a QR code image URL for the published page.

**OpenAI:** No

### When to call (UI)

- Step 7: after publish, show QR code for sharing

### Request

```
POST /page/{alias}/qr
```

Optional body:

```json
{
  "size": 300
}
```

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `size` | No | 300 | QR image size in pixels |

### Response JSON

```json
{
  "alias": "john",
  "publicUrl": "https://wpage.app/john",
  "qrCodeUrl": "https://api.wpage.app/qr/john.png"
}
```

### Error responses

| Status | Example `detail` |
|--------|------------------|
| 404 | Page not found for alias: john |
| 400 | Page is not published yet |
| 502 | Failed to generate QR code |

### UI usage notes

- Show QR code with “Scan to visit my page.”
- Pair with Copy Link for `publicUrl`.
- Only enable after successful publish (Step 6).

---

## End-to-End Flow (Example)

```
1. User picks "Job Seeker / Resume"
2. User types: "Experienced nurse looking for hospital roles in Manchester."
3. POST /generate-page
   → AI creates page with Title, About, Contact sections
4. User edits Title and About
   PUT /page/john
5. GET /render/john
   → Preview in WebView
6. POST /page/john/publish
   → Page goes live
7. POST /page/john/qr
   → Show QR + copy https://wpage.app/john
```

---

## Section Types (UI ↔ API)

The UI shows friendly names. The API stores them as `section.type`:

| UI label | API `type` |
|----------|------------|
| Title | `title` |
| Subtitle | (part of title section `content.subheading`) |
| About | `about` |
| Services | `services` |
| Contact | `contact` |
| Links | `links` |
| Images | `image` |
| Videos | `video` |
| Tables | `table` |

Additional generated sections (Call to Action, Footer) may appear but do not need dedicated editor screens unless the product adds them later.

---

## Developer Notes (not for end-user UI)

The backend may store sections internally using a structured JSON format. Flutter/Web clients should:

1. Treat `page.sections` as the editable content model.
2. Never surface internal field names like `blocks`, `hero`, or `call_to_action` to users.
3. Only call OpenAI via `POST /generate-page`.
4. Use Firestore-backed endpoints for all read, update, render, publish, and QR operations.

---

## Health Check

```
GET /health
```

Response:

```json
{
  "status": "ok"
}
```

Use for app startup connectivity checks.
