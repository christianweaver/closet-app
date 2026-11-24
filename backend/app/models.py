import uuid
from datetime import datetime

from typing import Literal, get_args
from pgvector.sqlalchemy import Vector
from sqlalchemy import CheckConstraint, DateTime, Text, func, text
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

Category = Literal["top", "bottom", "shoes", "outerwear", "accessory"]
Status = Literal["uploading", "processing", "ready", "failed"]

CATEGORIES = get_args(Category)
STATUSES = get_args(Status)
EMBEDDING_DIM = 512  # OpenCLIP ViT-B-32 produces 512-number embeddings


def _sql_in(column: str, values: tuple[str, ...]) -> str:
    """Build a SQL condition like: category IN ('top', 'bottom')."""
    quoted = ", ".join(f"'{v}'" for v in values)
    return f"{column} IN ({quoted})"


class Base(DeclarativeBase):
    pass


class Item(Base):
    __tablename__ = "items"
    __table_args__ = (
        CheckConstraint(_sql_in("category", CATEGORIES), name="ck_items_category"),
        CheckConstraint(_sql_in("status", STATUSES), name="ck_items_status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    image_key: Mapped[str | None] = mapped_column(Text)
    category: Mapped[str | None] = mapped_column(Text, index=True)
    colors: Mapped[list[str]] = mapped_column(
        ARRAY(Text), server_default=text("'{}'")
    )
    style_tags: Mapped[list[str]] = mapped_column(
        ARRAY(Text), server_default=text("'{}'")
    )
    embedding: Mapped[list[float] | None] = mapped_column(Vector(EMBEDDING_DIM))
    status: Mapped[str] = mapped_column(Text, server_default=text("'uploading'"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )


class Outfit(Base):
    __tablename__ = "outfits"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    item_ids: Mapped[list[uuid.UUID]] = mapped_column(ARRAY(UUID(as_uuid=True)))
    liked: Mapped[bool | None]
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )