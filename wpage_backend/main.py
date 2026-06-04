from fastapi import FastAPI

from app.routes.page_routes import router as page_router
from app.utils.config import init_firebase

app = FastAPI(title="Wpage Backend")

init_firebase()
app.include_router(page_router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
