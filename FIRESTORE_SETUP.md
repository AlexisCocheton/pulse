# Configuration Firestore

## Problème de connexion résolu

Si vous rencontrez l'erreur "Unable to establish connection on channel", suivez ces étapes :

### 1. Redémarrer l'application
Après avoir ajouté `cloud_firestore`, vous devez :
- Arrêter complètement l'application
- Redémarrer avec `flutter run` ou redémarrer depuis l'IDE

### 2. Vérifier les règles de sécurité Firestore

Dans la console Firebase (https://console.firebase.google.com), allez dans Firestore Database > Rules.

Pour le développement, utilisez ces règles temporaires (⚠️ PAS pour la production) :

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /profiles/{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Pour la production**, vous devrez implémenter des règles de sécurité appropriées avec Firebase Authentication.

### 3. Vérifier que Firestore est activé

Dans la console Firebase :
1. Allez dans "Firestore Database"
2. Cliquez sur "Créer une base de données"
3. Choisissez "Démarrer en mode test" (pour le développement)
4. Sélectionnez une région (ex: `europe-west1` pour l'Europe)

### 4. Vérifier les permissions Android

Assurez-vous que votre `AndroidManifest.xml` inclut :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

### 5. Nettoyer et reconstruire

Si le problème persiste :
```bash
flutter clean
flutter pub get
flutter run
```

## Structure des données

Les profils sont stockés dans la collection `profiles` avec cette structure :

```
profiles/
  {userId}/
    name: string
    age: number
    location: string
    sports: array<string>
    level: string
    bio: string
    image: string (URL)
    createdAt: timestamp
    updatedAt: timestamp
```
