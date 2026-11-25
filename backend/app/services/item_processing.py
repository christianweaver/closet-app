import logging
import time
import uuid

from sqlalchemy import update

from app import storage
from app.db import SessionLocal
from app.ml import tagger
from app.ml.colors import dominant_colors
from app.ml.images import load_image, on_white
from app.models import Item

logger = logging.getLogger(__name__)


def process_item(item_id: uuid.UUID) -> None:
    """Background job: tag an uploaded item and mark it ready (or failed)."""
    start = time.perf_counter()
    with SessionLocal() as session:          
        item = session.get(Item, item_id)
        if item is None:
            logger.info("Item %s was deleted before processing; skipping", item_id)
            return

        try:
            image = load_image(storage.download_bytes(item.image_key))
            result = tagger.get_model().tag(on_white(image))
            colors = dominant_colors(image)
        except Exception:
            logger.exception("Processing failed for item %s", item_id)
            item.status = "failed"
            session.commit()
            return

        item.category = result.category
        item.style_tags = result.style_tags
        item.colors = colors
        item.embedding = result.embedding
        item.status = "ready"
        session.commit()

    logger.info(
        "Processed item %s in %.2fs: category=%s (%.0f%%) colors=%s styles=%s",
        item_id, time.perf_counter() - start, result.category,
        result.category_confidence * 100, colors, result.style_tags,
    )


def recover_stuck_items() -> None:
    """At startup, nothing can be mid-processing; anything marked so was interrupted."""
    with SessionLocal() as session:
        outcome = session.execute(
            update(Item).where(Item.status == "processing").values(status="failed")
        )
        session.commit()
    if outcome.rowcount:
        logger.warning("Marked %d interrupted item(s) as failed", outcome.rowcount)