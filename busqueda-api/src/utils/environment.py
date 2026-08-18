from decouple import config

OPENAI_API_KEY: str = config("OPENAI_API_KEY")
OPENAI_EMBEDDING_MODEL: str = config("OPENAI_EMBEDDING_MODEL", default="text-embedding-3-small")

QDRANT_URL: str = config("QDRANT_URL")
QDRANT_KEY: str = config("QDRANT_KEY")
QDRANT_COLLECTION_NAME: str = config("QDRANT_COLLECTION_NAME")
