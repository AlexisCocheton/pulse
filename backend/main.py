from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import firebase_admin
from firebase_admin import credentials, firestore
from services import MatchingService
import os
from dotenv import load_dotenv

load_dotenv()

# Initialiser Firebase
if not firebase_admin.get_app():
    cred = credentials.Certificate(os.getenv('FIREBASE_CREDENTIALS_PATH', 'serviceAccountKey.json'))
    firebase_admin.initialize_app(cred)

db = firestore.client()
matching_service = MatchingService(db)

app = FastAPI(title="Pulse Matching API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class MatchCandidatesRequest(BaseModel):
    userId: str
    maxDistance: float = 5.0
    limit: int = 10


class MatchQualityRequest(BaseModel):
    userId1: str
    userId2: str


class InteractionRequest(BaseModel):
    userId: str
    targetId: str
    action: str  # 'like', 'pass', 'match', 'unmatch'


@app.get("/api/match-candidates")
async def get_match_candidates(
    userId: str,
    maxDistance: float = 5.0,
    limit: int = 10,
):
    """
    Récupère les candidats de matching pour un utilisateur.

    Filtre:
    - Même ville
    - Distance < maxDistance km
    - Au moins 1 sport en commun
    - Pas l'utilisateur lui-même
    - Pas déjà interagis
    """
    try:
        candidates = await matching_service.get_match_candidates(
            userId=userId,
            maxDistance=maxDistance,
            limit=limit,
        )
        return {"candidates": candidates}
    except Exception as e:
        return {"error": str(e)}, 500


@app.post("/api/match-quality")
async def calculate_match_quality(request: MatchQualityRequest):
    """
    Calcule le score de compatibilité entre deux utilisateurs.

    Score basé sur:
    - Sports en commun (30%)
    - Passions en commun (10%)
    - Proximité d'âge (10%)
    """
    try:
        score = await matching_service.calculate_match_score(
            userId1=request.userId1,
            userId2=request.userId2,
        )
        return {"score": score}
    except Exception as e:
        return {"error": str(e)}, 500


@app.post("/api/track-interaction")
async def track_interaction(request: InteractionRequest):
    """
    Enregistre une interaction (like, pass, match, unmatch) pour le ML futur.
    """
    try:
        await matching_service.track_interaction(
            userId=request.userId,
            targetId=request.targetId,
            action=request.action,
        )
        return {"success": True}
    except Exception as e:
        return {"error": str(e)}, 500


@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
