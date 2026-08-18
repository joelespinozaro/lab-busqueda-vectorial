from src.integrations.db_vectorial_integration import DbVectorialIntegration
from src.integrations.embedding_integration import EmbeddingIntegration


class SearchService:
    def __init__(self, embedding: EmbeddingIntegration, dbVectorial: DbVectorialIntegration) -> None:
        self._embedding = embedding
        self._dbVectorial = dbVectorial

    def search(self, question: str, limit: int = 5) -> dict:
        vector = self._embedding.generate_embedding(question)
        results = self._dbVectorial.search(vector, limit=limit)
        return {
            "input": question,
            "results": results,
        }