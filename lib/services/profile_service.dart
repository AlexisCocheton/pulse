import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'profiles';

  // Créer ou mettre à jour un profil
  Future<void> createOrUpdateProfile({
    required String userId,
    required String name,
    required int age,
    required String location,
    required List<String> sports,
    required String level,
    required String bio,
    String? imageUrl,
    List<String>? passions,
    String? lookingFor,
    int? height,
    String? ethnicity,
  }) async {
    try {
      // Vérifier que Firestore est initialisé
      await _firestore.enableNetwork();

      final data = <String, dynamic>{
        'name': name,
        'age': age,
        'location': location,
        'sports': sports,
        'level': level,
        'bio': bio,
        'image': imageUrl ??
            'https://images.unsplash.com/photo-1658702041515-18275b138fda?auto=format&fit=crop&w=800&q=80',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (passions != null) data['passions'] = passions;
      if (lookingFor != null) data['lookingFor'] = lookingFor;
      if (height != null) data['height'] = height;
      if (ethnicity != null) data['ethnicity'] = ethnicity;

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Erreur Firestore (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du profil: $e');
    }
  }

  // Récupérer un profil par userId
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du profil: $e');
    }
  }

  // Récupérer tous les profils (pour la découverte)
  Stream<List<Map<String, dynamic>>> getAllProfiles({String? excludeUserId}) {
    try {
      return _firestore.collection(_collectionName).snapshots().map((snapshot) {
        return snapshot.docs
            .where((doc) => excludeUserId == null || doc.id != excludeUserId)
            .map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
      });
    } catch (e) {
      throw Exception('Erreur lors de la récupération des profils: $e');
    }
  }

  // Récupérer tous les profils une seule fois (pour la découverte)
  Future<List<Map<String, dynamic>>> getAllProfilesOnce({String? excludeUserId}) async {
    try {
      final snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs
          .where((doc) => excludeUserId == null || doc.id != excludeUserId)
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des profils: $e');
    }
  }

  // Supprimer un profil
  Future<void> deleteProfile(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du profil: $e');
    }
  }

  // ========== FONCTIONS DE MATCH ==========

  // Enregistrer une interaction (like, pass, super like)
  Future<void> addInteraction({
    required String fromUserId,
    required String toUserId,
    required String type, // 'like', 'pass', 'super_like'
  }) async {
    try {
      await _firestore
          .collection('interactions')
          .doc('$fromUserId-$toUserId')
          .set({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'type': type,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Erreur Firestore (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'interaction: $e');
    }
  }

  // Vérifier si c'est un match (les deux se sont likés)
  Future<bool> checkMatch(String userId1, String userId2) async {
    try {
      final interaction1 = await _firestore
          .collection('interactions')
          .doc('$userId1-$userId2')
          .get();
      final interaction2 = await _firestore
          .collection('interactions')
          .doc('$userId2-$userId1')
          .get();

      if (interaction1.exists && interaction2.exists) {
        final data1 = interaction1.data();
        final data2 = interaction2.data();
        final type1 = data1?['type'] as String?;
        final type2 = data2?['type'] as String?;

        // Match si les deux ont liké ou super liké (pas de pass)
        return (type1 == 'like' || type1 == 'super_like') &&
            (type2 == 'like' || type2 == 'super_like');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Créer un match
  Future<void> createMatch(String userId1, String userId2) async {
    try {
      final matchId = [userId1, userId2]..sort();
      await _firestore
          .collection('matches')
          .doc('${matchId[0]}-${matchId[1]}')
          .set({
        'users': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Erreur Firestore (${e.code}): ${e.message}');
    } catch (e) {
      throw Exception('Erreur lors de la création du match: $e');
    }
  }

  // Récupérer les profils non vus et non passés
  Future<List<Map<String, dynamic>>> getDiscoverableProfiles(
    String currentUserId,
  ) async {
    try {
      // Récupérer toutes les interactions de l'utilisateur (like, pass, super_like)
      final interactions = await _firestore
          .collection('interactions')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();

      // Exclure tous les profils déjà interagis (pas seulement les passes)
      final excludedUserIds = {
        currentUserId,
        ...interactions.docs
            .map((doc) => doc.data()['toUserId'] as String),
      };

      // Récupérer tous les profils visibles sauf ceux exclus
      final snapshot = await _firestore.collection(_collectionName).get();
      return snapshot.docs
          .where((doc) => !excludedUserIds.contains(doc.id))
          .where((doc) => (doc.data()['isVisible'] as bool?) != false)
          .map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des profils: $e');
    }
  }

  // Signaler un utilisateur
  Future<void> reportUser({
    required String fromUserId,
    required String toUserId,
    required String reason,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw Exception('Erreur signalement (${e.code}): ${e.message}');
    }
  }

  // Se désassocier d'un match (unmatch)
  Future<void> unmatch(String userId1, String userId2) async {
    try {
      final matchId = ([userId1, userId2]..sort());
      final matchDocId = '${matchId[0]}-${matchId[1]}';

      final batch = _firestore.batch();
      batch.delete(_firestore.collection('matches').doc(matchDocId));
      batch.delete(_firestore.collection('interactions').doc('$userId1-$userId2'));
      batch.delete(_firestore.collection('interactions').doc('$userId2-$userId1'));
      await batch.commit();

      // Archiver la conversation
      await _firestore
          .collection('conversations')
          .doc(matchDocId)
          .set({'archived': true}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw Exception('Erreur unmatch (${e.code}): ${e.message}');
    }
  }

  // Récupérer les matches de l'utilisateur
  Future<List<Map<String, dynamic>>> getMatches(String userId) async {
    try {
      final matchesSnapshot = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();

      final matchUserIds = <String>{};
      for (var matchDoc in matchesSnapshot.docs) {
        final users = matchDoc.data()['users'] as List<dynamic>?;
        if (users != null) {
          for (var user in users) {
            if (user != userId) {
              matchUserIds.add(user.toString());
            }
          }
        }
      }

      if (matchUserIds.isEmpty) return [];

      // Récupérer les profils des matches
      final profiles = <Map<String, dynamic>>[];
      for (var matchUserId in matchUserIds) {
        final profile = await getProfile(matchUserId);
        if (profile != null) {
          profiles.add({'id': matchUserId, ...profile});
        }
      }

      return profiles;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des matches: $e');
    }
  }

  // Récupérer les profils qui ont liké l'utilisateur (likes reçus)
  Future<List<Map<String, dynamic>>> getLikesReceived(String userId) async {
    try {
      final interactions = await _firestore
          .collection('interactions')
          .where('toUserId', isEqualTo: userId)
          .where('type', whereIn: ['like', 'super_like'])
          .get();

      final likerIds = interactions.docs
          .map((doc) => doc.data()['fromUserId'] as String)
          .toList();

      if (likerIds.isEmpty) return [];

      final profiles = <Map<String, dynamic>>[];
      for (final likerId in likerIds) {
        final profile = await getProfile(likerId);
        if (profile != null) {
          profiles.add({'id': likerId, ...profile});
        }
      }
      return profiles;
    } catch (e) {
      return [];
    }
  }

  // Récupérer les statistiques d'un utilisateur
  Future<Map<String, int>> getStats(String userId) async {
    try {
      final likesGiven = await _firestore
          .collection('interactions')
          .where('fromUserId', isEqualTo: userId)
          .where('type', whereIn: ['like', 'super_like'])
          .get();

      final matches = await _firestore
          .collection('matches')
          .where('users', arrayContains: userId)
          .get();

      final likesReceived = await _firestore
          .collection('interactions')
          .where('toUserId', isEqualTo: userId)
          .where('type', whereIn: ['like', 'super_like'])
          .get();

      return {
        'matches': matches.size,
        'likesGiven': likesGiven.size,
        'likesReceived': likesReceived.size,
      };
    } catch (e) {
      return {'matches': 0, 'likesGiven': 0, 'likesReceived': 0};
    }
  }
}
