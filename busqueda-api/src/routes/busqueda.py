from fastapi import APIRouter

from src.controllers.chat_controller import handle_search
from src.dto.busqueda_dto import BusquedaRequest, BusquedaResponse

router = APIRouter()


@router.post("/api/busqueda", response_model=BusquedaResponse, tags=["busqueda"])
def busqueda(request: BusquedaRequest) -> BusquedaResponse:
    result = handle_search(question=request.input, limit=request.limit)
    return BusquedaResponse(**result)
