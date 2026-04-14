import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service de modération — lit et écrit les vraies données Firestore.
///
/// Collections concernées :
///   photo_reports   — résultats Safe Search (Cloud Function)
///   reports         — signalements utilisateurs
///   moderation_logs — journal des actions admin
///   profiles        — suspension / restauration
class ModerationService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get _adminId => FirebaseAuth.instance.currentUser?.uid ?? 'admin';

  // ── Streams ─────────────────────────────────────────────────────────────────

  /// Photos en attente de revue (flagged ou error, non encore traitées)
  Stream<List<Map<String, dynamic>>> get flaggedPhotos {
    return _db
        .collection('photo_reports')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((s) {
      final docs = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      // Approved automatiquement non visible, on affiche flagged + error en premier
      docs.sort((a, b) {
        const order = {'flagged': 0, 'error': 1, 'approved': 2};
        final aO = order[a['autoDecision']] ?? 3;
        final bO = order[b['autoDecision']] ?? 3;
        return aO.compareTo(bO);
      });
      return docs;
    });
  }

  /// Signalements utilisateurs, les non résolus en premier
  Stream<List<Map<String, dynamic>>> get userReports {
    return _db
        .collection('reports')
        .snapshots()
        .map((s) {
      final docs = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      docs.sort((a, b) {
        final aResolved = a['status'] != null && a['status'] != 'pending';
        final bResolved = b['status'] != null && b['status'] != 'pending';
        if (aResolved != bResolved) return aResolved ? 1 : -1;
        final aT = a['createdAt'] as Timestamp?;
        final bT = b['createdAt'] as Timestamp?;
        if (aT == null || bT == null) return 0;
        return bT.compareTo(aT);
      });
      return docs;
    });
  }

  /// Tous les profils (pour modération manuelle)
  Stream<List<Map<String, dynamic>>> get allProfiles {
    return _db.collection('profiles').snapshots().map((s) {
      final docs = s.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      // Suspendus en premier
      docs.sort((a, b) {
        final aSusp = (a['suspended'] as bool?) == true ? 0 : 1;
        final bSusp = (b['suspended'] as bool?) == true ? 0 : 1;
        return aSusp.compareTo(bSusp);
      });
      return docs;
    });
  }

  /// Journal des 50 dernières actions de modération
  Stream<List<Map<String, dynamic>>> get activityLogs {
    return _db
        .collection('moderation_logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Compteurs pour les badges ─────────────────────────────────────────────

  Stream<int> get pendingPhotosCount => _db
      .collection('photo_reports')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.size);

  Stream<int> get pendingReportsCount => _db
      .collection('reports')
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.size);

  Stream<int> get suspendedCount => _db
      .collection('profiles')
      .where('suspended', isEqualTo: true)
      .snapshots()
      .map((s) => s.size);

  // ── Actions sur les photos ────────────────────────────────────────────────

  /// Approuver une photo (Safe Search OK, pas de suppression)
  Future<void> approvePhoto(String userId) async {
    await _db.collection('photo_reports').doc(userId).update({
      'status': 'approved',
      'moderatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': _adminId,
    });
    await _log(userId: userId, action: 'photo_approved', reason: null);
  }

  /// Rejeter une photo : supprime du profil + Storage + log
  Future<void> rejectPhoto(String userId, String reason) async {
    const defaultImage =
        'https://images.unsplash.com/photo-1658702041515-18275b138fda?auto=format&fit=crop&w=800&q=80';

    final batch = _db.batch();
    batch.update(_db.collection('photo_reports').doc(userId), {
      'status': 'rejected',
      'reason': reason,
      'moderatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': _adminId,
    });
    batch.update(_db.collection('profiles').doc(userId), {
      'image': defaultImage,
    });
    await batch.commit();

    try {
      await _storage.ref().child('profiles/$userId/photo.jpg').delete();
    } catch (_) {
      // Fichier déjà supprimé ou inexistant
    }

    await _log(userId: userId, action: 'photo_rejected', reason: reason);
  }

  // ── Actions sur les signalements ─────────────────────────────────────────

  /// Ignorer un signalement
  Future<void> dismissReport(String reportId, String toUserId) async {
    await _db.collection('reports').doc(reportId).update({
      'status': 'dismissed',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _adminId,
    });
    await _log(userId: toUserId, action: 'report_dismissed', reason: null);
  }

  /// Avertir l'utilisateur signalé
  Future<void> warnUser(String reportId, String userId) async {
    final batch = _db.batch();
    batch.update(_db.collection('reports').doc(reportId), {
      'status': 'warned',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _adminId,
    });
    batch.update(_db.collection('profiles').doc(userId), {'warned': true});
    await batch.commit();
    await _log(
        userId: userId,
        action: 'profile_warned',
        reason: 'Avertissement suite à signalement');
  }

  /// Suspendre l'utilisateur signalé
  Future<void> suspendFromReport(String reportId, String userId) async {
    final batch = _db.batch();
    batch.update(_db.collection('reports').doc(reportId), {
      'status': 'suspended',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _adminId,
    });
    batch.update(_db.collection('profiles').doc(userId), {
      'suspended': true,
      'isVisible': false,
    });
    await batch.commit();
    await _log(
        userId: userId,
        action: 'profile_suspended',
        reason: 'Suspension suite à signalement');
  }

  // ── Actions sur les profils ───────────────────────────────────────────────

  Future<void> suspendProfile(String userId) async {
    await _db.collection('profiles').doc(userId).update({
      'suspended': true,
      'isVisible': false,
    });
    await _log(
        userId: userId, action: 'profile_suspended', reason: 'Suspension manuelle');
  }

  Future<void> restoreProfile(String userId) async {
    await _db.collection('profiles').doc(userId).update({
      'suspended': false,
      'isVisible': true,
    });
    await _log(userId: userId, action: 'profile_restored', reason: null);
  }

  // ── Journal ───────────────────────────────────────────────────────────────

  Future<void> _log({
    required String userId,
    required String action,
    required String? reason,
  }) async {
    await _db.collection('moderation_logs').add({
      'userId': userId,
      'action': action,
      'reason': reason,
      'adminId': _adminId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
