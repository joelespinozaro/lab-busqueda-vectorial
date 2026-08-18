from src.integrations.impl.openai_embedding_integration import OpenAIEmbeddingIntegration
from src.integrations.impl.qdrant_integration import QdrantIntegration
from src.services.search_service import SearchService


def handle_search(question: str, limit: int = 5) -> dict:
    embedding = OpenAIEmbeddingIntegration()
    dbVectorial = QdrantIntegration()
    service = SearchService(embedding=embedding, dbVectorial=dbVectorial)
    return service.search(question=question, limit=limit)
