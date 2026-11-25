import logging

from app.routers import items
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError

from app import storage
from app.db import engine, init_db
from app.ml import tagger

logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()  
    storage.ensure_bucket()  
    tagger.load_model()
    yield      # the app runs while we're paused here
    # anything after yield runs on shutdown


app = FastAPI(title="Closet App API", lifespan=lifespan)
app.include_router(items.router)


@app.get("/health")
def health():
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
    except SQLAlchemyError:
        logger.exception("Health check: database unreachable")
        return JSONResponse(
            status_code=503,
            content={"status": "error", "database": "unreachable"},
        )
    return {"status": "ok", "database": "ok"}