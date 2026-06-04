import re


def derive_alias(identity: str) -> str:
    identity = identity.strip()
    if "@" in identity:
        alias = identity.split("@")[0].lower()
    else:
        digits = re.sub(r"\D", "", identity)
        if len(digits) >= 4:
            alias = f"user{digits[-6:]}"
        else:
            alias = re.sub(r"[^a-z0-9]+", "-", identity.lower()).strip("-")
    alias = re.sub(r"[^a-z0-9_-]", "", alias)
    return alias[:40] or "page"
