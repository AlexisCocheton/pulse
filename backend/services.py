import math
from datetime import datetime
from typing import List, Dict, Any
from firebase_admin import firestore


class MatchingService:
    def __init__(self, db):
        self.db = db
        self.profiles_collection = "profiles"
        self.interactions_collection = "interactions"
        self.match_scores_collection = "match_scores"

    async def get_match_candidates(
        self,
        userId: str,
        maxDistance: float = 5.0,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """
        Récupère les candidats de matching triés par compatibilité.

        Filtres:
        - Pas l'utilisateur lui-même
        - Même ville
        - Distance < maxDistance km
        - Au moins 1 sport en commun
        - Pas déjà interagis
        """
        try:
            # 1. Récupérer le profil de l'utilisateur
            user_profile = self.db.collection(self.profiles_collection).document(userId).get()
            if not user_profile.exists:
                return []

            user_data = user_profile.to_dict()
            user_city = user_data.get("location", "").lower()
            user_sports = set(user_data.get("sports", []))
            user_lat = user_data.get("location_coords", {}).get("latitude")
            user_long = user_data.get("location_coords", {}).get("longitude")

            # 2. Récupérer l'historique d'interactions
            interactions_ref = self.db.collection(self.interactions_collection)
            interactions = interactions_ref.where(
                "fromUserId", "==", userId
            ).stream()
            excluded_users = {userId}
            for interaction in interactions:
                excluded_users.add(interaction.get("toUserId"))

            # 3. Récupérer tous les profils
            all_profiles = self.db.collection(self.profiles_collection).stream()
            candidates = []

            for profile in all_profiles:
                profile_id = profile.id
                if profile_id in excluded_users:
                    continue

                profile_data = profile.to_dict()

                # Vérifier la visibilité
                if not profile_data.get("isVisible", True):
                    continue

                # Filtre 1 : Même ville
                target_city = profile_data.get("location", "").lower()
                if target_city != user_city:
                    continue

                # Filtre 2 : Distance < maxDistance km
                if user_lat is not None and user_long is not None:
                    target_lat = profile_data.get("location_coords", {}).get("latitude")
                    target_long = profile_data.get("location_coords", {}).get("longitude")

                    if target_lat is not None and target_long is not None:
                        distance = self._calculate_distance(
                            user_lat, user_long, target_lat, target_long
                        )
                        if distance > maxDistance:
                            continue
                    else:
                        # Si le profil n'a pas de coordonnées, on le saute
                        continue

                # Filtre 3 : Au moins 1 sport en commun
                target_sports = set(profile_data.get("sports", []))
                common_sports = user_sports & target_sports
                if len(common_sports) < 1:
                    continue

                # Calculer le score de compatibilité
                score = self._calculate_compatibility_score(user_data, profile_data)

                candidates.append({
                    "id": profile_id,
                    "name": profile_data.get("name"),
                    "age": profile_data.get("age"),
                    "image": profile_data.get("image"),
                    "location": profile_data.get("location"),
                    "sports": profile_data.get("sports", []),
                    "bio": profile_data.get("bio"),
                    "compatibilityScore": score,
                    "commonSports": list(common_sports),
                })

            # Trier par score de compatibilité (décroissant)
            candidates.sort(key=lambda x: x["compatibilityScore"], reverse=True)

            # Retourner les top N candidats
            return candidates[:limit]

        except Exception as e:
            print(f"Erreur get_match_candidates: {e}")
            raise

    async def calculate_match_score(self, userId1: str, userId2: str) -> float:
        """
        Calcule le score de compatibilité détaillé entre deux utilisateurs.

        Score basé sur:
        - Sports en commun (0.30 * nombre_sports_commun / 5)
        - Passions en commun (0.10 * nombre_passions_commun / 10)
        - Proximité d'âge (0.10 * (1 - abs(age1 - age2) / 50))
        """
        try:
            doc1 = self.db.collection(self.profiles_collection).document(userId1).get()
            doc2 = self.db.collection(self.profiles_collection).document(userId2).get()

            if not doc1.exists or not doc2.exists:
                return 0.0

            data1 = doc1.to_dict()
            data2 = doc2.to_dict()

            score = self._calculate_compatibility_score(data1, data2)
            return score

        except Exception as e:
            print(f"Erreur calculate_match_score: {e}")
            return 0.0

    def _calculate_compatibility_score(self, user1: Dict, user2: Dict) -> float:
        """Calcule le score de compatibilité entre deux profils."""
        score = 0.0

        # 1. Sports en commun (30%)
        sports1 = set(user1.get("sports", []))
        sports2 = set(user2.get("sports", []))
        common_sports = len(sports1 & sports2)
        sports_score = min(common_sports / 5.0, 1.0)  # Max 5 sports comptent
        score += 0.30 * sports_score

        # 2. Passions en commun (10%)
        passions1 = set(user1.get("passions", []))
        passions2 = set(user2.get("passions", []))
        common_passions = len(passions1 & passions2)
        passions_score = min(common_passions / 10.0, 1.0)  # Max 10 passions comptent
        score += 0.10 * passions_score

        # 3. Proximité d'âge (10%)
        age1 = user1.get("age", 25)
        age2 = user2.get("age", 25)
        age_diff = abs(age1 - age2)
        age_score = max(1.0 - (age_diff / 50.0), 0.0)
        score += 0.10 * age_score

        # Bonus de base (50%) pour profil complet
        score += 0.50

        return min(score, 1.0)

    def _calculate_distance(self, lat1: float, long1: float, lat2: float, long2: float) -> float:
        """
        Calcule la distance en km entre deux points (formule de Haversine).
        """
        R = 6371  # Rayon de la Terre en km
        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_long = math.radians(long2 - long1)

        a = (
            math.sin(delta_lat / 2) ** 2
            + math.cos(lat1_rad)
            * math.cos(lat2_rad)
            * math.sin(delta_long / 2) ** 2
        )
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        distance = R * c

        return distance

    async def track_interaction(
        self, userId: str, targetId: str, action: str
    ) -> None:
        """
        Enregistre une interaction pour le ML futur.
        Collection: interactions/{userId-targetId}
        """
        try:
            interaction_doc = f"{userId}-{targetId}"
            self.db.collection(self.interactions_collection).document(
                interaction_doc
            ).set(
                {
                    "userId": userId,
                    "targetId": targetId,
                    "action": action,  # 'like', 'pass', 'match', 'unmatch'
                    "timestamp": datetime.now(),
                },
                merge=True,
            )
        except Exception as e:
            print(f"Erreur track_interaction: {e}")
            raise
