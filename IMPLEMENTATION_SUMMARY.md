# Pulse Matching System - Implémentation Complète

## 📋 Résumé des changements

Cette implémentation corrige 3 bugs critiques et ajoute un système de matching algorithmique en 2 phases.

---

## 🐛 Bugs corrigés

### 1. **Auto-matching** ❌ ➜ ✅
**Problème:** Un utilisateur pouvait se matcher lui-même.
**Solution:** 
- `MatchingService.get_match_candidates()` filtre `userId ≠ targetId`
- Backend Python vérifie `excluded_users = {userId}`

### 2. **Matching sans limite de distance** ❌ ➜ ✅
**Problème:** Les utilisateurs de villes différentes pouvaient se matcher.
**Solution:**
- Ajout de la géolocalisation (latitude/longitude) au profil
- Filtre obligatoire: **même ville** + **distance < maxDistance km**
- Formule Haversine pour calcul précis de distance

### 3. **Distance non configurable** ❌ ➜ ✅
**Problème:** La distance était aléatoire et non contrôlable.
**Solution:**
- Slider dans `privacy_screen.dart` : 5-100 km (défaut 5 km)
- Sauvegarde dans Firestore `users/{userId}.maxDistance`
- L'API backend utilise cette valeur pour filtrer

---

## 📦 Phase 1 : Géolocalisation + Distance

### App Changes (Flutter)

#### 1. **pubspec.yaml**
- ✅ Ajouté: `geolocator: ^11.0.0`
- ✅ Ajouté: `http: ^1.1.0`

#### 2. **Permissions Android**
- `android/app/src/main/AndroidManifest.xml`
- ✅ `ACCESS_FINE_LOCATION`
- ✅ `ACCESS_COARSE_LOCATION`

#### 3. **Services Flutter**

**`lib/services/location_service.dart`** (NEW)
```dart
- getCurrentLocation() → {latitude, longitude}
- calculateDistance(lat1, long1, lat2, long2) → km
```

**`lib/services/matching_service.dart`** (NEW)
```dart
- getMatchCandidates(userId, maxDistance, limit)
- calculateMatchScore(userId1, userId2)
- trackInteraction(userId, targetId, action)
```

**`lib/services/profile_service.dart`** (MODIFIED)
```dart
- createOrUpdateProfile(): Added latitude, longitude params
- Firestore storage: location_coords = {latitude, longitude}
```

#### 4. **Screens Flutter**

**`profile_creation_screen.dart`** (MODIFIED)
- Étape 1: Ajout bouton "Utiliser ma localisation"
- Récupère lat/long via LocationService
- Affiche coordonnées avec confirmation ✓
- Sauvegarde dans Firestore

**`privacy_screen.dart`** (MODIFIED)
- Nouvelle section: "Distance de recherche"
- Slider 5-100 km (défaut 5 km)
- Affiche distance en temps réel
- Sauvegarde `maxDistance` dans Firestore

**`discover_screen.dart`** (MODIFIED)
- Essaye d'abord l'API backend `/api/match-candidates`
- Fallback: logique locale avec filtrage par distance
- Affiche distance réelle calculée (km)
- Prépare appels API pour futur tracking

---

## 🚀 Phase 2 : Backend Python + Algorithme

### Backend FastAPI

#### Installation

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# Télécharger serviceAccountKey.json depuis Firebase
python main.py
```

API disponible sur: `http://localhost:8000`

#### Fichiers

**`backend/main.py`**
- FastAPI app avec 3 endpoints
- CORS configuré pour Flutter
- Intégration Firebase Admin SDK

**`backend/services.py`**
- `MatchingService` : logique de matching
- Filtre: même ville, distance < maxDistance, 1+ sports communs
- Score de compatibilité (0-1):
  - 50% : bonus base (profil complet)
  - 30% : sports en commun
  - 10% : passions en commun
  - 10% : proximité d'âge
- Formule Haversine pour distance

**`backend/requirements.txt`**
- fastapi, uvicorn, firebase-admin, python-dotenv, pydantic

**`backend/.env.example`**
- Variables d'environnement pour configuration

**`backend/README.md`**
- Instructions installation locale
- Instructions déploiement OVH/Heroku
- Documentation API complète
- Explication algorithme

#### Endpoints API

**GET `/api/match-candidates?userId=X&maxDistance=50&limit=10`**
```json
{
  "candidates": [
    {
      "id": "user123",
      "name": "Alice",
      "age": 28,
      "location": "Paris",
      "sports": ["Yoga", "Fitness"],
      "compatibilityScore": 0.87,
      "commonSports": ["Yoga"]
    }
  ]
}
```

**POST `/api/match-quality`**
```json
{ "userId1": "X", "userId2": "Y" }
→ { "score": 0.87 }
```

**POST `/api/track-interaction`**
```json
{ "userId": "X", "targetId": "Y", "action": "like" }
→ { "success": true }
```

---

## 🧠 Algorithme de Matching

### Calcul du score de compatibilité

```
Score final = Bonus(50%) + Sports(30%) + Passions(10%) + Âge(10%)

Bonus(50%)           = 0.5 (profil complet)
Sports(30%)          = 30% × min(common_sports / 5, 1.0)
Passions(10%)        = 10% × min(common_passions / 10, 1.0)
Âge(10%)             = 10% × (1 - |age1 - age2| / 50)

Score max = 1.0
```

### Filtres obligatoires (avant scoring)

1. ✅ Pas l'utilisateur lui-même (`userId ≠ targetId`)
2. ✅ Même ville (`location == location`)
3. ✅ Distance < maxDistance km (Haversine)
4. ✅ Au moins 1 sport en commun
5. ✅ Pas déjà interagis (comme, passer, match)
6. ✅ Profil visible (`isVisible == true`)

### Distance (Haversine)

```python
R = 6371 km  # Rayon Terre
Δlat = lat2 - lat1
Δlong = long2 - long1
a = sin²(Δlat/2) + cos(lat1)·cos(lat2)·sin²(Δlong/2)
c = 2·atan2(√a, √(1-a))
distance = R·c
```

---

## 📊 Firestore Schema

### Collection: `profiles/{userId}`
```
{
  "name": "Alice",
  "age": 28,
  "location": "Paris",
  "sports": ["Yoga", "Fitness"],
  "level": "Intermédiaire",
  "bio": "...",
  "isVisible": true,
  "showAge": true,
  "showLocation": true,
  
  // NEW FIELDS
  "location_coords": {
    "latitude": 48.8566,
    "longitude": 2.3522
  },
  "maxDistance": 5.0,
  
  "createdAt": timestamp,
  "updatedAt": timestamp
}
```

### Collection: `interactions/{userId1-userId2}`
```
{
  "userId": "user1",
  "targetId": "user2",
  "action": "like",  // like, pass, match, unmatch
  "timestamp": timestamp
}
```

---

## 🔄 Flux Utilisateur

### 1. Création de Profil
```
ProfileCreationScreen
  → Étape 1: Nom, Âge, Ville
  → [NEW] Bouton "Utiliser ma localisation"
    → LocationService.getCurrentLocation()
    → Firestore: location_coords
  → Étapes 2-5: Sports, niveau, bio, credentials
  → Firestore.set(profile)
```

### 2. Configuration Distance
```
PrivacyScreen
  → Slider: Distance max (5-100 km)
  → Firestore.set(maxDistance)
```

### 3. Découverte
```
DiscoverScreen._loadProfiles()
  1. Récupère maxDistance depuis Firestore
  2. Essaye API: MatchingService.getMatchCandidates()
     ↓
     Backend Python filtre + score
  3. Fallback local si API indisponible
     ↓
     LocationService.calculateDistance()
  4. Affiche profils triés par score
  5. Swipe → _handleAction() → addInteraction()
```

---

## 🚀 Déploiement

### Local Development

```bash
# Flutter (app)
flutter pub get
flutter run

# Python (backend)
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### Production OVH

Voir `backend/README.md` pour:
- ☁️ Heroku deployment
- 🖥️ OVH Cloud Compute
- 🔧 Gunicorn + Nginx setup

---

## 📈 Phase 2 (Futur) : Machine Learning

Quand données suffisantes (~1000+ interactions):

```python
from sklearn.ensemble import RandomForestClassifier

X = [sports_sim, passions_sim, age_diff, distance, ...]
y = [liked=1, passed=0, ...]

model.fit(X, y)
score = model.predict_proba(new_pair)[1]  # 0-1
```

**Données déjà collectées via:**
- `MatchingService.track_interaction()` → Firestore
- Interactions historiques: like, pass, match, unmatch

---

## ✅ Checklist Implémentation

### App Flutter
- [x] LocationService (getCurrentLocation, calculateDistance)
- [x] MatchingService (API client)
- [x] profile_creation_screen: géolocalisation
- [x] privacy_screen: slider distance
- [x] discover_screen: API matching + fallback
- [x] ProfileService: latitude/longitude storage
- [x] pubspec.yaml: geolocator, http

### Backend Python
- [x] FastAPI app (main.py)
- [x] MatchingService (services.py)
- [x] Firebase Admin integration
- [x] 3 API endpoints
- [x] Algorithme score (sports, passions, âge)
- [x] Filtres (distance, même ville, 1+ sport)
- [x] Haversine distance
- [x] requirements.txt
- [x] .env.example
- [x] README documentation

### Permissions
- [x] Android: ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION

### Testing
- [ ] Tester l'app Flutter localement
- [ ] Tester le backend Python localement
- [ ] Tester l'intégration API
- [ ] Tester la fallback
- [ ] Déployer sur OVH

---

## 🎯 Prochaines étapes

1. **Tester localement**
   ```bash
   # Terminal 1: Backend
   cd backend && python main.py
   
   # Terminal 2: App
   flutter run
   ```

2. **Tester les permissions** (demande localisation)
3. **Vérifier Firestore** (location_coords, maxDistance)
4. **Configurer déploiement OVH**
5. **Implémenter Phase 2 ML** (quand données disponibles)

---

## 📝 Notes

- **Algorithme actuel:** Déterministe et transparent
- **Filtrages:** Stricts (même ville obligatoire)
- **Distance:** Calcul précis (Haversine, km)
- **Fallback:** Seamless si API down
- **Future ML:** Données prêtes pour Phase 2
