import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'welcome_screen.dart';
import 'profile_creation_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  Map<String, dynamic>? _profile;
  Map<String, int> _stats = {
    'matches': 0,
    'likesGiven': 0,
    'likesReceived': 0
  };
  bool _isLoading = true;
  bool _isUploadingPhoto = false;
  String? _error;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _userId = await _authService.getCurrentUserId();

      if (_userId == null) {
        setState(() {
          _error = 'Aucun utilisateur connecté';
          _isLoading = false;
        });
        return;
      }

      final profile = await _profileService.getProfile(_userId!);
      final stats = await _profileService.getStats(_userId!);

      if (profile == null) {
        setState(() {
          _error = 'Profil non trouvé';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _profile = profile;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Caméra'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUpload(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _isUploadingPhoto = true);

      final url = await _storageService.uploadProfilePhoto(
        _userId!,
        File(picked.path),
      );

      await _profileService.createOrUpdateProfile(
        userId: _userId!,
        name: _profile!['name'] as String? ?? '',
        age: _profile!['age'] as int? ?? 18,
        location: _profile!['location'] as String? ?? '',
        sports: List<String>.from(_profile!['sports'] as List? ?? []),
        level: _profile!['level'] as String? ?? 'Intermédiaire',
        bio: _profile!['bio'] as String? ?? '',
        imageUrl: url,
      );

      if (!mounted) return;
      setState(() {
        _profile = {..._profile!, 'image': url};
        _isUploadingPhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur upload : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToEdit() async {
    if (_profile == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(currentProfile: _profile!),
      ),
    );
    if (updated == true) _loadProfile();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content:
            const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.logout();
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  int _getLevelStars(String level) {
    switch (level) {
      case 'Débutant':
        return 1;
      case 'Intermédiaire':
        return 3;
      case 'Avancé':
        return 4;
      case 'Expert':
        return 5;
      default:
        return 3;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _profile == null) {
      final isNotFound = _profile == null ||
          (_error != null && _error!.contains('non trouvé'));
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNotFound
                      ? Icons.person_add_outlined
                      : Icons.error_outline,
                  size: 72,
                  color: isNotFound
                      ? Colors.blue.shade300
                      : Colors.red.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  isNotFound
                      ? 'Vous n\'avez pas encore de profil'
                      : (_error ?? 'Profil non trouvé'),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (isNotFound)
                  Text(
                    'Créez votre profil pour commencer à trouver des partenaires sportifs.',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isNotFound) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ProfileCreationScreen(),
                        ),
                      );
                    } else {
                      _loadProfile();
                    }
                  },
                  icon: Icon(isNotFound ? Icons.add : Icons.refresh),
                  label:
                      Text(isNotFound ? 'Créer mon profil' : 'Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final sports = (_profile!['sports'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        [];
    final passions = (_profile!['passions'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        [];
    final level = _profile!['level'] as String? ?? 'Intermédiaire';
    final levelStars = _getLevelStars(level);
    final name = _profile!['name'] as String? ?? 'Utilisateur';
    final age = _profile!['age'] as int? ?? 0;
    final location = _profile!['location'] as String? ?? '';
    final bio = _profile!['bio'] as String? ?? '';
    final imageUrl = _profile!['image'] as String? ?? '';
    final lookingFor = _profile!['lookingFor'] as String?;
    final height = _profile!['height'] as int?;
    final ethnicity = _profile!['ethnicity'] as String?;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Cover + Avatar ──
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Gradient cover
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.secondary,
                          colorScheme.primary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(right: 8, top: 4),
                          child: IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: Colors.white),
                            onPressed: () {},
                            tooltip: 'Paramètres',
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Avatar overlapping cover
                  Positioned(
                    bottom: -54,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 16,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? Container(
                                      color: Colors.black54,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: Colors.white),
                                      ),
                                    )
                                  : (imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _defaultAvatar(),
                                        )
                                      : _defaultAvatar()),
                            ),
                          ),
                        ),
                        // Camera badge (bottom left)
                        Positioned(
                          bottom: 2,
                          left: 2,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 13, color: Colors.white),
                          ),
                        ),
                        // Edit badge (bottom right)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: _navigateToEdit,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 15, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Space for avatar overflow
              const SizedBox(height: 68),
              // ── Name & Location ──
              Text(
                '$name, $age',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              if (location.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      location,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14),
                    ),
                  ],
                ),
              const SizedBox(height: 22),
              // ── Content ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _StatsRow(stats: _stats),
                    const SizedBox(height: 14),
                    _SportsSection(sports: sports),
                    const SizedBox(height: 14),
                    _LevelSection(level: level, stars: levelStars),
                    const SizedBox(height: 14),
                    _BioSection(bio: bio),
                    if (lookingFor != null && lookingFor.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _LookingForSection(lookingFor: lookingFor),
                    ],
                    if (passions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _PassionsSection(passions: passions),
                    ],
                    if (height != null ||
                        (ethnicity != null && ethnicity.isNotEmpty)) ...[
                      const SizedBox(height: 14),
                      _PhysiqueSection(height: height, ethnicity: ethnicity),
                    ],
                    const SizedBox(height: 14),
                    _SettingsButtons(
                      onEditTap: _navigateToEdit,
                      onPrivacyTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyScreen(),
                        ),
                      ),
                      onNotificationsTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _LogoutButton(onLogout: _logout),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade200,
      child:
          Icon(Icons.person, size: 52, color: Colors.grey.shade400),
    );
  }
}

// ─────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final Map<String, int> stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    Widget card(String value, String label, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        card('${stats['matches'] ?? 0}', 'Matchs',
            Icons.favorite, Colors.pinkAccent),
        const SizedBox(width: 8),
        card('${stats['likesGiven'] ?? 0}', 'Likes donnés',
            Icons.thumb_up_outlined, const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        card('${stats['likesReceived'] ?? 0}', 'Likes reçus',
            Icons.star_outline, Colors.amber.shade700),
      ],
    );
  }
}

class _SportsSection extends StatelessWidget {
  final List<String> sports;

  const _SportsSection({required this.sports});

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Mes sports',
      icon: Icons.emoji_events_outlined,
      child: sports.isEmpty
          ? Text(
              'Aucun sport sélectionné',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13),
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sports
                  .map(
                    (s) => Chip(
                      label: Text(s,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          )),
                      backgroundColor: const Color(0xFFDBEAFE),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  final String level;
  final int stars;

  const _LevelSection({required this.level, required this.stars});

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Niveau',
      icon: Icons.bar_chart,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(level,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500)),
          Row(
            children: List.generate(5, (i) {
              final active = i < stars;
              return Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: Icon(
                  active ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color:
                      active ? const Color(0xFF2563EB) : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _BioSection extends StatelessWidget {
  final String bio;

  const _BioSection({required this.bio});

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'À propos',
      icon: Icons.person_outline,
      child: Text(
        bio.isEmpty ? 'Aucune bio pour le moment…' : bio,
        style: TextStyle(
          fontSize: 14,
          color: bio.isEmpty ? Colors.grey.shade400 : Colors.black87,
          height: 1.5,
        ),
      ),
    );
  }
}

class _SettingsButtons extends StatelessWidget {
  final VoidCallback? onEditTap;
  final VoidCallback? onPrivacyTap;
  final VoidCallback? onNotificationsTap;

  const _SettingsButtons({
    this.onEditTap,
    this.onPrivacyTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          _SettingsTile(
            icon: Icons.edit_outlined,
            label: 'Modifier mon profil',
            iconColor: const Color(0xFF2563EB),
            onTap: onEditTap,
            isFirst: true,
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Confidentialité',
            iconColor: Colors.grey.shade600,
            onTap: onPrivacyTap,
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            iconColor: Colors.grey.shade600,
            onTap: onNotificationsTap,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onLogout;

  const _LogoutButton({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: BorderSide(
              color: Colors.redAccent.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('Se déconnecter',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _LookingForSection extends StatelessWidget {
  final String lookingFor;

  const _LookingForSection({required this.lookingFor});

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Je cherche',
      icon: Icons.favorite_outline,
      child: Row(
        children: [
          const Icon(Icons.favorite, size: 18, color: Color(0xFFEC4899)),
          const SizedBox(width: 8),
          Text(
            lookingFor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PassionsSection extends StatelessWidget {
  final List<String> passions;

  const _PassionsSection({required this.passions});

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Passions',
      icon: Icons.interests_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: passions
            .map(
              (p) => Chip(
                label: Text(
                  p,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
                backgroundColor: const Color(0xFFDCFCE7),
                side: const BorderSide(color: Color(0xFF86EFAC)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PhysiqueSection extends StatelessWidget {
  final int? height;
  final String? ethnicity;

  const _PhysiqueSection({this.height, this.ethnicity});

  @override
  Widget build(BuildContext context) {
    return _CardSection(
      title: 'Physique',
      icon: Icons.accessibility_new_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (height != null)
            _InfoRow(
              icon: Icons.height,
              label: 'Taille',
              value: '$height cm',
            ),
          if (height != null &&
              ethnicity != null &&
              ethnicity!.isNotEmpty)
            const SizedBox(height: 8),
          if (ethnicity != null && ethnicity!.isNotEmpty)
            _InfoRow(
              icon: Icons.public_outlined,
              label: 'Origine',
              value: ethnicity!,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Text(
          '$label : ',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget child;

  const _CardSection({
    required this.title,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
