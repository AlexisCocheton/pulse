import 'package:cloud_firestore/cloud_firestore.dart';

class SeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _profiles = [
    // ── Femmes ──────────────────────────────────────────────
    {
      'id': 'seed_sophie_01',
      'name': 'Sophie',
      'age': 24,
      'location': 'Paris 8ème',
      'sports': ['Tennis', 'Yoga', 'Course'],
      'level': 'Intermédiaire',
      'bio':
          'Passionnée de sport depuis toujours ! Je cherche des partenaires motivés pour des sessions matinales avant le boulot. Tennis le samedi, yoga le dimanche. 🎾',
      'image':
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_emma_02',
      'name': 'Emma',
      'age': 27,
      'location': 'Paris 12ème',
      'sports': ['Natation', 'Cyclisme', 'Fitness'],
      'level': 'Avancé',
      'bio':
          'Triathlète en préparation. Je cherche des partenaires d\'entraînement sérieux pour m\'aider à progresser. 3x par semaine à la piscine.',
      'image':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_camille_03',
      'name': 'Camille',
      'age': 22,
      'location': 'Paris 5ème',
      'sports': ['Yoga', 'Fitness'],
      'level': 'Débutant',
      'bio':
          'Étudiante en médecine, le sport est ma soupape ! J\'adore le yoga du matin et les cours de fitness en soirée. Cherche quelqu\'un de sympa et motivant.',
      'image':
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_marie_04',
      'name': 'Marie',
      'age': 31,
      'location': 'Paris 15ème',
      'sports': ['Tennis', 'Course', 'Natation'],
      'level': 'Expert',
      'bio':
          'Coach sportif certifiée. Classée en tennis, participante régulière aux semi-marathons de Paris. Si tu veux progresser vite, je suis là ! 💪',
      'image':
          'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_julie_05',
      'name': 'Julie',
      'age': 26,
      'location': 'Paris 18ème',
      'sports': ['Football', 'Course', 'Fitness'],
      'level': 'Intermédiaire',
      'bio':
          'Footballeuse en ligue amateur depuis 5 ans. Coureuse du dimanche matin. J\'aime allier sport et convivialité, on fait souvent un brunch après !',
      'image':
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_lea_06',
      'name': 'Léa',
      'age': 29,
      'location': 'Vincennes',
      'sports': ['Cyclisme', 'Course', 'Yoga'],
      'level': 'Avancé',
      'bio':
          'Cycliste passionnée, je fais le tour du Bois de Vincennes tous les matins avant le travail. Cherche compagnons de route pour le weekend. 🚴‍♀️',
      'image':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=800&q=80',
    },
    // ── Hommes ──────────────────────────────────────────────
    {
      'id': 'seed_lucas_07',
      'name': 'Lucas',
      'age': 28,
      'location': 'Paris 11ème',
      'sports': ['Basketball', 'Fitness', 'Course'],
      'level': 'Avancé',
      'bio':
          'Fan de basketball depuis gamin, je joue en équipe le mercredi soir au gymnase de la République. Toujours partant pour un footing matinal aussi !',
      'image':
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_thomas_08',
      'name': 'Thomas',
      'age': 32,
      'location': 'Paris 16ème',
      'sports': ['Tennis', 'Natation', 'Cyclisme'],
      'level': 'Expert',
      'bio':
          'Licencié FFT, joueur de tennis classé 15/4. Nageur du dimanche matin à la piscine Molitor. Cherche partenaire de tennis pour m\'entraîner en semaine.',
      'image':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_alexandre_09',
      'name': 'Alexandre',
      'age': 25,
      'location': 'Paris 9ème',
      'sports': ['Course', 'Fitness', 'Football'],
      'level': 'Intermédiaire',
      'bio':
          'Je prépare mon premier marathon de Paris ! Entraînements 3x/semaine le long du canal Saint-Martin. Ouvert à tous niveaux, l\'essentiel c\'est la bonne humeur.',
      'image':
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_nathan_10',
      'name': 'Nathan',
      'age': 23,
      'location': 'Montreuil',
      'sports': ['Football', 'Basketball', 'Fitness'],
      'level': 'Intermédiaire',
      'bio':
          'Footeux du dimanche en quête de partenaires réguliers. J\'organise des matchs de foot à 5 chaque samedi dans le 93. Plus on est de fous, plus on rit ! ⚽',
      'image':
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_pierre_11',
      'name': 'Pierre',
      'age': 34,
      'location': 'Boulogne-Billancourt',
      'sports': ['Cyclisme', 'Natation', 'Course'],
      'level': 'Expert',
      'bio':
          'Ironman finisher x3. Je cherche des partenaires d\'entraînement pour les trois disciplines. Niveau avancé requis, on part tôt le matin le weekend.',
      'image':
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=800&q=80',
    },
    {
      'id': 'seed_maxime_12',
      'name': 'Maxime',
      'age': 30,
      'location': 'Paris 20ème',
      'sports': ['Yoga', 'Course', 'Basketball'],
      'level': 'Débutant',
      'bio':
          'Reconverti au sport après des années de sédentarité ! Débutant mais très motivé. J\'adore les cours de yoga en plein air et les joggings tranquilles.',
      'image':
          'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=800&q=80',
    },
  ];

  Future<void> seedProfiles() async {
    final batch = _firestore.batch();

    for (final p in _profiles) {
      final id = p['id'] as String;
      final data = Map<String, dynamic>.from(p)..remove('id');
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      batch.set(
        _firestore.collection('profiles').doc(id),
        data,
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> deleteSeededProfiles() async {
    final batch = _firestore.batch();
    for (final p in _profiles) {
      batch.delete(
          _firestore.collection('profiles').doc(p['id'] as String));
    }
    await batch.commit();
  }

  int get profileCount => _profiles.length;
}
