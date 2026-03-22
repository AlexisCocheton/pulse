const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

// Notif quand quelqu'un te like
exports.onNewLike = onDocumentCreated(
  "interactions/{docId}",
  async (event) => {
    const data = event.data.data();
    if (data.type !== "like") return;

    const toUserId = data.toUserId;
    const fromUserId = data.fromUserId;

    // Récupère le token FCM du destinataire
    const toUserDoc = await getFirestore()
      .collection("profiles")
      .doc(toUserId)
      .get();
    const fcmToken = toUserDoc.data()?.fcmToken;
    if (!fcmToken) return;

    // Vérifie les préférences notifs
    if (toUserDoc.data()?.notifLikes === false) return;

    // Récupère le nom de l'expéditeur
    const fromUserDoc = await getFirestore()
      .collection("profiles")
      .doc(fromUserId)
      .get();
    const fromName = fromUserDoc.data()?.name ?? "Quelqu'un";

    // Envoie la notif
    await getMessaging().send({
      token: fcmToken,
      notification: {
        title: "Nouveau like 💙",
        body: `${fromName} vous a liké !`,
      },
      android: {
        notification: { channelId: "pulse_default" },
      },
    });
  }
);

// Notif pour un nouveau match
exports.onNewMatch = onDocumentCreated(
  "matches/{matchId}",
  async (event) => {
    const data = event.data.data();
    const [uid1, uid2] = data.users ?? [];

    const [doc1, doc2] = await Promise.all([
      getFirestore().collection("profiles").doc(uid1).get(),
      getFirestore().collection("profiles").doc(uid2).get(),
    ]);

    const sends = [];

    if (doc1.data()?.fcmToken && doc1.data()?.notifMatches !== false) {
      sends.push(getMessaging().send({
        token: doc1.data().fcmToken,
        notification: { title: "Nouveau match ! 🎉", body: `Vous avez matché avec ${doc2.data()?.name} !` },
      }));
    }
    if (doc2.data()?.fcmToken && doc2.data()?.notifMatches !== false) {
      sends.push(getMessaging().send({
        token: doc2.data().fcmToken,
        notification: { title: "Nouveau match ! 🎉", body: `Vous avez matché avec ${doc1.data()?.name} !` },
      }));
    }

    await Promise.all(sends);
  }
);

// Notif pour un nouveau message
exports.onNewMessage = onDocumentCreated(
  "conversations/{convId}/messages/{msgId}",
  async (event) => {
    const data = event.data.data();
    const senderId = data.senderId;
    const convId = event.params.convId;

    // Le receiverId n'est pas dans le message — on le lit depuis la conversation
    const convDoc = await getFirestore()
      .collection("conversations")
      .doc(convId)
      .get();
    const users = convDoc.data()?.users ?? [];
    const receiverId = users.find((u) => u !== senderId);
    if (!receiverId) return;

    const receiverDoc = await getFirestore()
      .collection("profiles")
      .doc(receiverId)
      .get();
    const fcmToken = receiverDoc.data()?.fcmToken;
    if (!fcmToken) return;
    if (receiverDoc.data()?.notifMessages === false) return;

    const senderDoc = await getFirestore()
      .collection("profiles")
      .doc(data.senderId)
      .get();
    const senderName = senderDoc.data()?.name ?? "Quelqu'un";

    await getMessaging().send({
      token: fcmToken,
      notification: {
        title: senderName,
        body: data.text?.substring(0, 100) ?? "Nouveau message",
      },
    });
  }
);
