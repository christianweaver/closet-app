import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator
from typing import Literal
from app.models import Category, Status


# ---------- Items ----------

class ItemCreate(BaseModel):
    """Body for POST /items."""
    image_key: str | None = None
    category: Category | None = None
    colors: list[str] = Field(default_factory=list)
    style_tags: list[str] = Field(default_factory=list)


class ItemUpdate(BaseModel):
    """Body for PATCH /items/{id}. Every field is optional: send only what changes."""
    category: Category | None = None
    colors: list[str] | None = None
    style_tags: list[str] | None = None

    @field_validator("colors", "style_tags")
    @classmethod
    def reject_null_lists(cls, value: list[str] | None) -> list[str]:
        if value is None:
            raise ValueError("send [] to clear this field, not null")
        return value


class ItemRead(BaseModel):
    """What the API returns for an item. Note: no embedding."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    image_key: str | None
    category: Category | None
    colors: list[str]
    style_tags: list[str]
    status: Status
    created_at: datetime


# ---------- Outfits (used on Day 6) ----------

class OutfitCreate(BaseModel):
    item_ids: list[uuid.UUID] = Field(min_length=1)
    liked: bool | None = None


class OutfitRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    item_ids: list[uuid.UUID]
    liked: bool | None
    created_at: datetime

# ---------- Uploads ----------

class UploadUrlRequest(BaseModel):
    content_type: Literal["image/png", "image/jpeg"]


class UploadUrlResponse(BaseModel):
    item: ItemRead
    upload_url: str
    expires_in: int