const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");
const { getStorage } = require("firebase-admin/storage");
const https = require("https");

initializeApp();

// Secret à créer via : firebase functions:secrets:set VISION_API_KEY
const VISION_API_KEY = defineSecret("VISION_API_KEY");

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Envoie une notification FCM et supprime le token si invalide/expiré.
 * Retourne true si envoyé, false sinon (token absent, désactivé, ou erreur non-fatale).
 */
async function sendNotification(token, payload) {
  if (!token) return false;
  try {
    await getMessaging().send({ token, ...payload });
    return true;
  } catch (err) {
    // Codes indiquant un token définitivement invalide → on le supprime du profil
    const staleTokenCodes = [
      "messaging/registration-token-not-registered",
      "messaging/invalid-registration-token",
      "messaging/invalid-argument",
    ];
    if (staleTokenCodes.includes(err.code)) {
      // Retrouver l'uid associé au token pour le nettoyer
      const snap = await getFirestore()
        .collection("profiles")
        .where("fcmToken", "==", token)
        .limit(1)
        .get();
      if (!snap.empty) {
        await snap.docs[0].ref.update({ fcmToken: null });
      }
    }
    console.error("[FCM] Erreur envoi :", err.code, err.message);
    return false;
  }
}

// ─── Notifications ────────────────────────────────────────────────────────────

exports.onNewLike = onDocumentCreated(
  "interactions/{docId}",
  async (event) => {
    try {
      if (!event.data) return;
      const data = event.data.data();
      // Notifier pour like ET super_like
      if (data.type !== "like" && data.type !== "super_like") return;

      const { toUserId, fromUserId } = data;
      if (!toUserId || !fromUserId) return;

      const [toUserDoc, fromUserDoc] = await Promise.all([
        getFirestore().collection("profiles").doc(toUserId).get(),
        getFirestore().collection("profiles").doc(fromUserId).get(),
      ]);

      if (!toUserDoc.exists) return;
      const fcmToken = toUserDoc.data()?.fcmToken;
      if (!fcmToken || toUserDoc.data()?.notifLikes === false) return;

      const fromName = fromUserDoc.exists ? (fromUserDoc.data()?.name ?? "Quelqu'un") : "Quelqu'un";
      const isSuperLike = data.type === "super_like";

      await sendNotification(fcmToken, {
        notification: {
          title: isSuperLike ? "Super like ⭐" : "Nouveau like 💙",
          body: isSuperLike ? `${fromName} vous a super liké !` : `${fromName} vous a liké !`,
        },
        android: { notification: { channelId: "pulse_default" } },
      });
    } catch (err) {
      console.error("[onNewLike] Erreur :", err);
    }
  }
);

exports.onNewMatch = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    try {
      if (!event.data) return;
      const data = event.data.data();
      const users = data.users;
      if (!Array.isArray(users) || users.length < 2) return;
      const [uid1, uid2] = users;
      if (!uid1 || !uid2) return;

      const [doc1, doc2] = await Promise.all([
        getFirestore().collection("profiles").doc(uid1).get(),
        getFirestore().collection("profiles").doc(uid2).get(),
      ]);

      const name1 = doc1.exists ? (doc1.data()?.name ?? "Quelqu'un") : "Quelqu'un";
      const name2 = doc2.exists ? (doc2.data()?.name ?? "Quelqu'un") : "Quelqu'un";

      const sends = [];
      if (doc1.exists && doc1.data()?.fcmToken && doc1.data()?.notifMatches !== false) {
        sends.push(sendNotification(doc1.data().fcmToken, {
          notification: { title: "Nouveau match ! 🎉", body: `Vous avez matché avec ${name2} !` },
          android: { notification: { channelId: "pulse_default" } },
        }));
      }
      if (doc2.exists && doc2.data()?.fcmToken && doc2.data()?.notifMatches !== false) {
        sends.push(sendNotification(doc2.data().fcmToken, {
          notification: { title: "Nouveau match ! 🎉", body: `Vous avez matché avec ${name1} !` },
          android: { notification: { channelId: "pulse_default" } },
        }));
      }
      await Promise.all(sends);
    } catch (err) {
      console.error("[onNewMatch] Erreur :", err);
    }
  }
);

exports.onNewMessage = onDocumentCreated(
  "conversations/{convId}/messages/{msgId}",
  async (event) => {
    try {
      if (!event.data) return;
      const data = event.data.data();
      const senderId = data.senderId;
      const convId = event.params.convId;
      if (!senderId) return;

      const convDoc = await getFirestore().collection("conversations").doc(convId).get();
      if (!convDoc.exists) return;
      const users = convDoc.data()?.users ?? [];
      const receiverId = users.find((u) => u !== senderId);
      if (!receiverId) return;

      const [receiverDoc, senderDoc] = await Promise.all([
        getFirestore().collection("profiles").doc(receiverId).get(),
        getFirestore().collection("profiles").doc(senderId).get(),
      ]);

      if (!receiverDoc.exists) return;
      const fcmToken = receiverDoc.data()?.fcmToken;
      if (!fcmToken || receiverDoc.data()?.notifMessages === false) return;

      const senderName = senderDoc.exists ? (senderDoc.data()?.name ?? "Quelqu'un") : "Quelqu'un";

      await sendNotification(fcmToken, {
        notification: {
          title: senderName,
          body: data.text?.substring(0, 100) ?? "Nouveau message",
        },
        android: { notification: { channelId: "pulse_default" } },
      });
    } catch (err) {
      console.error("[onNewMessage] Erreur :", err);
    }
  }
);

// ─── Modération Safe Search ───────────────────────────────────────────────────

/**
 * Déclenché à chaque upload dans Firebase Storage.
 * Analyse uniquement les photos de profil : profiles/{userId}/photo.jpg
 * Stocke le résultat dans la collection Firestore `photo_reports`.
 *
 * Déploiement :
 *   firebase functions:secrets:set VISION_API_KEY
 *   firebase deploy --only functions
 */
exports.analyzeProfilePhoto = onObjectFinalized(
  { secrets: [VISION_API_KEY], region: 'us-west1' },
  async (event) => {
    const filePath = event.data.name;
    const bucket = event.data.bucket;

    // Filtre : uniquement profiles/{userId}/photo.jpg
    const match = filePath.match(/^profiles\/([^/]+)\/photo\.jpg$/);
    if (!match) return;

    const userId = match[1];
    const db = getFirestore();

    try {
      // URL publique (storage.rules autorise allow read: if true — token inutile)
      const imageUrl = `https://firebasestorage.googleapis.com/v0/b/${bucket}/o/${encodeURIComponent(filePath)}?alt=media`;

      // Télécharge l'image et l'envoie en base64 (plus fiable que GCS URI)
      const fileRef = getStorage().bucket(bucket).file(filePath);
      const [fileContents] = await fileRef.download();
      const base64Image = fileContents.toString('base64');
      const safeSearch = await callVisionSafeSearch(base64Image, VISION_API_KEY.value());

      // Règles de modération → décision automatique
      const { decision, reason } = evaluateContent(safeSearch);

      // Stocke le rapport dans Firestore (doc ID = userId pour lookup rapide)
      await db.collection("photo_reports").doc(userId).set({
        userId,
        imageUrl,
        storagePath: filePath,
        ...safeSearch,
        autoDecision: decision,
        // approved → auto-approuvé, rejected → auto-rejeté, flagged/error → attente admin
        status: decision === "rejected" ? "rejected" : decision === "approved" ? "approved" : "pending",
        reason,
        analyzedAt: FieldValue.serverTimestamp(),
        moderatedAt: null,
        moderatedBy: null,
      });

      // Rejet automatique : remplace la photo par l'image par défaut
      if (decision === "rejected") {
        await db.collection("profiles").doc(userId).update({
          image: "https://images.unsplash.com/photo-1658702041515-18275b138fda?auto=format&fit=crop&w=800&q=80",
        });
        await db.collection("moderation_logs").add({
          userId,
          action: "photo_auto_rejected",
          reason,
          adminId: "auto",
          timestamp: FieldValue.serverTimestamp(),
        });
      }

      console.log(`[SafeSearch] ${userId} → ${decision} (adult:${safeSearch.adult} violence:${safeSearch.violence} racy:${safeSearch.racy})`);
    } catch (err) {
      console.error(`[SafeSearch] Erreur pour ${userId}:`, err);

      // En cas d'erreur : marque comme pending pour revue manuelle
      await db.collection("photo_reports").doc(userId).set({
        userId,
        imageUrl: null,
        storagePath: filePath,
        adult: "UNKNOWN",
        violence: "UNKNOWN",
        medical: "UNKNOWN",
        racy: "UNKNOWN",
        spoof: "UNKNOWN",
        autoDecision: "error",
        status: "pending",
        reason: `Erreur d'analyse : ${err.message}`,
        analyzedAt: FieldValue.serverTimestamp(),
        moderatedAt: null,
        moderatedBy: null,
      });
    }
  }
);

/**
 * Appelle l'API Google Vision Safe Search via HTTPS.
 * Reçoit l'image en base64 pour garantir l'accès sans permission GCS.
 */
function callVisionSafeSearch(base64Image, apiKey) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({
      requests: [{
        image: { content: base64Image },
        features: [{ type: "SAFE_SEARCH_DETECTION" }],
      }],
    });

    const options = {
      hostname: "vision.googleapis.com",
      path: `/v1/images:annotate?key=${apiKey}`,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        try {
          const json = JSON.parse(data);
          if (json.error) return reject(new Error(json.error.message));
          // Erreur par requête (quota, format non supporté, etc.)
          const responseError = json.responses?.[0]?.error;
          if (responseError) return reject(new Error(responseError.message ?? "Vision API per-request error"));
          const a = json.responses?.[0]?.safeSearchAnnotation ?? {};
          resolve({
            adult:    a.adult    ?? "UNKNOWN",
            violence: a.violence ?? "UNKNOWN",
            medical:  a.medical  ?? "UNKNOWN",
            racy:     a.racy     ?? "UNKNOWN",
            spoof:    a.spoof    ?? "UNKNOWN",
          });
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on("error", reject);
    req.setTimeout(20000, () => req.destroy(new Error("Vision API timeout")));
    req.write(body);
    req.end();
  });
}

/**
 * Niveaux de sévérité Safe Search (0 = très improbable → 4 = très probable)
 */
const SEV = {
  VERY_UNLIKELY: 0,
  UNLIKELY: 1,
  POSSIBLE: 2,
  LIKELY: 3,
  VERY_LIKELY: 4,
  UNKNOWN: -1,
};

function sev(level) {
  return SEV[level] ?? -1;
}

/**
 * Applique les règles de modération et retourne { decision, reason }.
 *
 * Rejet automatique :
 *   - adult ≥ VERY_LIKELY
 *   - violence ≥ VERY_LIKELY
 *
 * Signalement (revue manuelle) :
 *   - adult ≥ LIKELY
 *   - adult ≥ POSSIBLE et racy ≥ POSSIBLE (combiné)
 *   - violence ≥ LIKELY
 *
 * Approuvé automatiquement : tout le reste
 */
function evaluateContent({ adult, violence, racy }) {
  if (sev(adult) >= sev("VERY_LIKELY"))
    return { decision: "rejected", reason: "Contenu adulte explicite (VERY_LIKELY)" };
  if (sev(violence) >= sev("VERY_LIKELY"))
    return { decision: "rejected", reason: "Contenu violent explicite (VERY_LIKELY)" };
  if (sev(adult) >= sev("LIKELY"))
    return { decision: "flagged", reason: "Contenu adulte probable (LIKELY)" };
  if (sev(adult) >= sev("POSSIBLE") && sev(racy) >= sev("POSSIBLE"))
    return { decision: "flagged", reason: "Contenu suggestif combiné (adult+racy ≥ POSSIBLE)" };
  if (sev(violence) >= sev("LIKELY"))
    return { decision: "flagged", reason: "Contenu violent probable (LIKELY)" };
  return { decision: "approved", reason: null };
}
