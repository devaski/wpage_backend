import json
import os
from pathlib import Path

import firebase_admin
from dotenv import load_dotenv
from firebase_admin import credentials, firestore
from openai import OpenAI

load_dotenv()

_BACKEND_ROOT = Path(__file__).resolve().parent.parent.parent
_LOCAL_SERVICE_ACCOUNT_FILE = _BACKEND_ROOT / "firebase_service_account.json"

PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "https://wpage.app").rstrip("/")
API_BASE_URL = os.getenv("API_BASE_URL", "https://wpage.app").rstrip("/")

openai_client = None
if os.getenv("OPENAI_API_KEY"):
    openai_client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))


def _load_service_account_dict() -> dict | None:
    json_env = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
    if json_env:
        return json.loads(json_env)
    if _LOCAL_SERVICE_ACCOUNT_FILE.is_file():
        return json.loads(_LOCAL_SERVICE_ACCOUNT_FILE.read_text())
    return None


def _resolve_credentials_path() -> str | None:
    path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
    if not path:
        return None
    if os.path.isfile(path):
        return path
    json_path = f"{path}.json" if not path.endswith(".json") else path
    return json_path if os.path.isfile(json_path) else None


def init_firebase() -> None:
    if firebase_admin._apps:
        return
    service_account = _load_service_account_dict()
    if service_account:
        firebase_admin.initialize_app(credentials.Certificate(service_account))
        return
    credentials_path = _resolve_credentials_path()
    if not credentials_path:
        return
    firebase_admin.initialize_app(credentials.Certificate(credentials_path))


def get_firestore_client():
    if not firebase_admin._apps:
        return None
    return firestore.client()

