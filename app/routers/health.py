from fastapi import APIRouter

router = APIRouter()


def _health_payload():
    return {"status": "ok", "service": "rendement-agricole-api"}


@router.get("/health")
def health_check():
    """Vérification que l'API est disponible."""
    return _health_payload()


@router.get("/api/health")
def health_check_api():
    """Version website-friendly via le proxy Vite (/api)."""
    return _health_payload()
