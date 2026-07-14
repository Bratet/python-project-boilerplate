from fastapi import FastAPI

app = FastAPI(title="app")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
