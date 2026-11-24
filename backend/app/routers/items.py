import uuid
from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db import get_session
from app.models import Category, Item
from app.schemas import ItemCreate, ItemRead, ItemUpdate

router = APIRouter(prefix="/items", tags=["items"])

SessionDep = Annotated[Session, Depends(get_session)]


def get_item_or_404(session: Session, item_id: uuid.UUID) -> Item:
    item = session.get(Item, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail="Item not found")
    return item


@router.post("", response_model=ItemRead, status_code=status.HTTP_201_CREATED)
def create_item(body: ItemCreate, session: SessionDep):
    item = Item(**body.model_dump())
    session.add(item)
    session.commit()
    session.refresh(item)
    return item


@router.get("", response_model=list[ItemRead])
def list_items(
    session: SessionDep,
    category: Category | None = None,
    color: str | None = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    stmt = select(Item).order_by(Item.created_at.desc(), Item.id)
    if category is not None:
        stmt = stmt.where(Item.category == category)
    if color is not None:
        stmt = stmt.where(Item.colors.contains([color]))
    stmt = stmt.limit(limit).offset(offset)
    return session.scalars(stmt).all()


@router.get("/{item_id}", response_model=ItemRead)
def get_item(item_id: uuid.UUID, session: SessionDep):
    return get_item_or_404(session, item_id)

@router.patch("/{item_id}", response_model=ItemRead)
def update_item(item_id: uuid.UUID, body: ItemUpdate, session: SessionDep):
    item = get_item_or_404(session, item_id)
    for field, value in body.model_dump(exclude_unset=True).items():
        setattr(item, field, value)
    session.commit()
    session.refresh(item)
    return item


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_item(item_id: uuid.UUID, session: SessionDep) -> None:
    item = get_item_or_404(session, item_id)
    session.delete(item)
    session.commit()