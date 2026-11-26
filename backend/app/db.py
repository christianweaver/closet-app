import os

from collections.abc import Iterator
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy import create_engine, text

DATABASE_URL = os.environ["DATABASE_URL"]

engine = create_engine(
    DATABASE_URL, 
    pool_pre_ping=True,
    echo=os.environ.get("SQL_ECHO") == "1",
)

def init_db() -> None:
    from app.models import Base

    with engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        Base.metadata.create_all(conn)

        conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_items_embedding_hnsw"
            " ON items USING hnsw (embedding vector_cosine_ops)"
        ))

SessionLocal = sessionmaker(bind=engine)

def get_session() -> Iterator[Session]:
   with SessionLocal() as session:
        yield session