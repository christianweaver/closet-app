from fastapi import FastAPI

app = FastAPI(title="Closet App API")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}