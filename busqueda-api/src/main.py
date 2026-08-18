import uvicorn
from fastapi import FastAPI

from src.routes.busqueda import router
from src.utils.logger import get_logger

logger = get_logger(__name__)

app = FastAPI(
    title="Búsqueda Vectorial",
    description="API de búsqueda semántica con embeddings OpenAI y Qdrant.",
    version="1.0.0",
)

app.include_router(router)


if __name__ == "__main__":
    logger.info("Iniciando servidor en puerto 8080")
    uvicorn.run("src.main:app", host="0.0.0.0", port=8080, reload=False)
