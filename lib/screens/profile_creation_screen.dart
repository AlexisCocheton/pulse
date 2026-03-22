import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main_tabs_screen.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  int _step = 1;
  bool _isSaving = false;

  String name = '';
  String age = '';
  String city = '';
  String bio = '';
  final List<String> sports = [];
  String level = '';
  String email = '';
  String password = '';
  String passwordConfirm = '';
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final levels = const ['Débutant', 'Intermédiaire', 'Avancé', 'Expert'];

  final availableSports = const [
    ('running', Icons.directions_run, 'Course'),
    ('tennis', Icons.sports_tennis, 'Tennis'),
    ('basketball', Icons.sports_basketball, 'Basketball'),
    ('yoga', Icons.self_improvement, 'Yoga'),
    ('cycling', Icons.directions_bike, 'Cyclisme'),
    ('swimming', Icons.pool, 'Natation'),
    ('fitness', Icons.fitness_center, 'Fitness'),
    ('football', Icons.sports_soccer, 'Football'),
    ('volleyball', Icons.sports_volleyball, 'Volleyball'),
    ('golf', Icons.golf_course, 'Golf'),
    ('skiing', Icons.downhill_skiing, 'Ski'),
    ('hiking', Icons.hiking, 'Randonnée'),
    ('boxing', Icons.sports_mma, 'Boxe'),
    ('handball', Icons.sports_handball, 'Handball'),
    ('rugby', Icons.sports_rugby, 'Rugby'),
    ('padel', Icons.sports_tennis, 'Padel'),
    ('climbing', Icons.terrain, 'Escalade'),
    ('pilates', Icons.accessibility_new, 'Pilates'),
  ];

  bool get _isStepValid {
    switch (_step) {
      case 1:
        return name.isNotEmpty && age.isNotEmpty && city.isNotEmpty;
      case 2:
        return sports.isNotEmpty;
      case 3:
        return level.isNotEmpty;
      case 4:
        return bio.isNotEmpty;
      case 5:
        return email.isNotEmpty &&
            password.length >= 6 &&
            password == passwordConfirm;
      default:
        return false;
    }
  }

  Future<void> _next() async {
    if (_step < 5) {
      setState(() => _step++);
    } else {
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      // 1. Créer le compte Firebase Auth
      final userId = await _authService.signUp(email.trim(), password);

      // 2. Convertir les IDs de sports en noms lisibles
      final sportNames = sports.map((id) {
        final sport = availableSports.firstWhere((s) => s.$1 == id);
        return sport.$3;
      }).toList();

      // 3. Sauvegarder le profil dans Firestore
      await _profileService.createOrUpdateProfile(
        userId: userId,
        name: name,
        age: int.tryParse(age) ?? 25,
        location: city,
        sports: sportNames,
        level: level,
        bio: bio,
      );

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainTabsScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Cet email est déjà utilisé. Connectez-vous à la place.';
          break;
        case 'weak-password':
          msg = 'Mot de passe trop faible (minimum 6 caractères).';
          break;
        case 'invalid-email':
          msg = 'Adresse email invalide.';
          break;
        default:
          msg = 'Erreur de création de compte : ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _back() {
    if (_step > 1) {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Création de profil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Étape $_step/5',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: index == 4 ? 0 : 8,
                            ),
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: index < _step
                                  ? colorScheme.secondary
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildStepContent(),
                  ),
                ),
              ),
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    if (_step > 1)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _back,
                          child: const Text('Retour'),
                        ),
                      ),
                    if (_step > 1) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isStepValid && !_isSaving) ? _next : null,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        label: Text(_isSaving
                            ? 'Sauvegarde...'
                            : (_step == 5 ? 'Terminer' : 'Suivant')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.secondary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              colorScheme.secondary.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.indigo],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Qui êtes-vous ?',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Commencez par vos informations de base',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Prénom',
            ),
            onChanged: (v) => setState(() => name = v),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Âge',
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => age = v),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Ville',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            onChanged: (v) => setState(() => city = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.indigo],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Vos sports',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sélectionnez les sports que vous pratiquez',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableSports.map((tuple) {
              final id = tuple.$1;
              final icon = tuple.$2;
              final label = tuple.$3;
              final selected = sports.contains(id);
              return ChoiceChip(
                label: Text(label),
                avatar: Icon(icon, size: 18),
                selected: selected,
                onSelected: (_) {
                  setState(() {
                    if (selected) {
                      sports.remove(id);
                    } else {
                      sports.add(id);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.indigo],
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Votre niveau',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quel est votre niveau global ?',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.separated(
            itemCount: levels.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final currentLevel = levels[index];
              final selected = level == currentLevel;
              return ListTile(
                onTap: () => setState(() => level = currentLevel),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selected ? Colors.blue : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                tileColor:
                    selected ? Colors.blue.withOpacity(0.05) : Colors.white,
                title: Text(currentLevel),
                trailing: selected
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.indigo],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Présentez-vous',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajoutez une description pour attirer vos futurs partenaires',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade300,
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.grey.shade500,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ajoutez une photo (non fonctionnel dans ce prototype)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'À propos de vous',
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            maxLength: 300,
            onChanged: (v) => setState(() => bio = v),
          ),
        ],
      ),
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue, Colors.indigo],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Créez votre compte',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ces identifiants vous permettront de vous connecter',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (v) => setState(() => email = v),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            onChanged: (v) => setState(() => password = v),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'Confirmer le mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePasswordConfirm
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(
                    () => _obscurePasswordConfirm = !_obscurePasswordConfirm),
              ),
              errorText: passwordConfirm.isNotEmpty && password != passwordConfirm
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
            obscureText: _obscurePasswordConfirm,
            onChanged: (v) => setState(() => passwordConfirm = v),
          ),
          const SizedBox(height: 8),
          Text(
            'Minimum 6 caractères',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

