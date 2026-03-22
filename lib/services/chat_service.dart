import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}-${sorted[1]}';
  }

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    final convId = getConversationId(senderId, receiverId);
    final batch = _firestore.batch();

    final msgRef = _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .doc();

    batch.set(msgRef, {
      'text': text,
      'senderId': senderId,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });

    batch.set(
      _firestore.collection('conversations').doc(convId),
      {
        'users': [senderId, receiverId],
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount_$receiverId': FieldValue.increment(1),
        'unreadCount_$senderId': 0,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getMessages(String uid1, String uid2) {
    final convId = getConversationId(uid1, uid2);
    return _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      // Tri client-side pour éviter tout besoin d'index
      docs.sort((a, b) {
        final aT = a['timestamp'] as Timestamp?;
        final bT = b['timestamp'] as Timestamp?;
        if (aT == null && bT == null) return 0;
        if (aT == null) return -1;
        if (bT == null) return 1;
        return aT.compareTo(bT); // chronologique
      });
      return docs;
    });
  }

  Stream<List<Map<String, dynamic>>> getConversations(String userId) {
    // Pas de orderBy ici : Firestore exigerait un index composite
    // (arrayContains + orderBy champ différent). On trie côté client.
    return _firestore
        .collection('conversations')
        .where('users', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .where((doc) => (doc.data()['archived'] as bool?) != true)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      docs.sort((a, b) {
        final aT = a['lastMessageTime'] as Timestamp?;
        final bT = b['lastMessageTime'] as Timestamp?;
        if (aT == null && bT == null) return 0;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return bT.compareTo(aT); // plus récent en premier
      });
      return docs;
    });
  }

  Future<void> markAsRead(String userId, String otherUserId) async {
    final convId = getConversationId(userId, otherUserId);
    try {
      await _firestore.collection('conversations').doc(convId).update({
        'unreadCount_$userId': 0,
      });
    } catch (_) {}
  }
}
