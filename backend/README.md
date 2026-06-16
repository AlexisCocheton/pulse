# Pulse Matching API

API backend pour l'algorithme de matching de Pulse.

## Installation locale

### 1. Créer un environnement virtuel Python

```bash
python -m venv venv
source venv/Scripts/activate  # Windows
# ou: source venv/bin/activate  # Linux/Mac
```

### 2. Installer les dépendances

```bash
pip install -r requirements.txt
```

### 3. Configurer Firebase

- Télécharger `serviceAccountKey.json` depuis Firebase Console:
  - Project Settings → Service Accounts → Generate new private key
- Placer le fichier à la racine du dossier `backend/`

### 4. Créer le fichier `.env`

```bash
cp .env.example .env
# Éditer .env si nécessaire
```

### 5. Lancer le serveur

```bash
python main.py
# ou pour dev avec rechargement automatique:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

L'API sera accessible sur: `http://localhost:8000`

Swagger docs: `http://localhost:8000/docs`

---

## Endpoints

### GET `/api/match-candidates`

Récupère les candidats de matching pour un utilisateur.

**Paramètres:**
- `userId` (string, requis): ID de l'utilisateur
- `maxDistance` (float, défaut: 5.0): Distance maximale en km
- `limit` (int, défaut: 10): Nombre de candidats à retourner

**Réponse:**
```json
{
  "candidates": [
    {
      "id": "user123",
      "name": "Alice",
      "age": 28,
      "image": "https://...",
      "location": "Paris",
      "sports": ["Yoga", "Fitness"],
      "bio": "...",
      "compatibilityScore": 0.87,
      "commonSports": ["Yoga"]
    }
  ]
}
```

### POST `/api/match-quality`

Calcule le score de compatibilité détaillé.

**Body:**
```json
{
  "userId1": "user123",
  "userId2": "user456"
}
```

**Réponse:**
```json
{
  "score": 0.87
}
```

### POST `/api/track-interaction`

Enregistre une interaction (pour le ML futur).

**Body:**
```json
{
  "userId": "user123",
  "targetId": "user456",
  "action": "like"
}
```

---

## Déploiement OVH

### Option 1: Heroku (recommandé pour démarrer)

```bash
pip install heroku
heroku login
heroku create pulse-matching-api
git push heroku main
```

### Option 2: OVH Cloud Compute

1. Créer une VM Linux (Ubuntu 22.04)
2. SSH et installer Python 3.10+
3. Cloner le repo et installer les dépendances
4. Utiliser Gunicorn + Nginx comme reverse proxy

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:8000 main:app
```

5. Configurer Nginx:
```nginx
server {
    listen 80;
    server_name api.pulse.fr;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Algorithme de Matching

Le score de compatibilité est calculé ainsi:

- **Sports en commun** (30%): Min(common_sports / 5, 1.0)
- **Passions en commun** (10%): Min(common_passions / 10, 1.0)
- **Proximité d'âge** (10%): 1 - (|age1 - age2| / 50)
- **Bonus base** (50%): Profil complet

Score final = somme de tous les pourcentages (max 1.0)

### Filtres avant le matching

1. **Même ville** (obligatoire)
2. **Distance < maxDistance km** (configurable par utilisateur)
3. **Au moins 1 sport en commun** (minimum requis)
4. **Pas déjà interagis** (like/pass/match)
5. **Profil visible** (isVisible = true)
6. **Pas l'utilisateur lui-même** (userId ≠ targetId)

---

## Architecture future (Phase 2)

Quand suffisamment de données seront collectées:

```python
# ML avec sklearn
from sklearn.ensemble import RandomForestClassifier

X = extract_features(interactions)  # sports, age, passions, distance
y = labels  # liked=1, passed=0

model.fit(X, y)
score = model.predict_proba(new_user_pair)[1]
```

Les données d'interaction sont déjà collectées via `/api/track-interaction` pour cette phase 2.
