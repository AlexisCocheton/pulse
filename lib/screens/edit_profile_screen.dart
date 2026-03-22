import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentProfile;

  const EditProfileScreen({super.key, required this.currentProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();
  final _authService = AuthService();

  late TextEditingController _nameCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ethnicityCtrl;
  late List<String> _selectedSports;
  late List<String> _selectedPassions;
  late String _selectedLevel;
  late String _lookingFor;
  bool _isSaving = false;

  static const _allSports = [
    'Course',
    'Tennis',
    'Basketball',
    'Yoga',
    'Cyclisme',
    'Natation',
    'Fitness',
    'Football',
    'Volleyball',
    'Golf',
    'Ski',
    'Randonnée',
    'Boxe',
    'Handball',
    'Rugby',
    'Padel',
    'Escalade',
    'Pilates',
  ];

  static const _levels = [
    'Débutant',
    'Intermédiaire',
    'Avancé',
    'Expert',
  ];

  static const _allPassions = [
    'Cuisine', 'Voyage', 'Musique', 'Lecture', 'Gaming', 'Cinéma',
    'Photo', 'Nature', 'Art', 'Danse', 'Tech', 'Animaux',
    'Mode', 'Bien-être', 'Foodie', 'Surf',
  ];

  static const _lookingForOptions = [
    'Amitié sportive',
    'Partenaire régulier',
    'Relation sérieuse',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.currentProfile['name'] as String? ?? '');
    _ageCtrl = TextEditingController(
        text: (widget.currentProfile['age'] as int? ?? 18).toString());
    _locationCtrl = TextEditingController(
        text: widget.currentProfile['location'] as String? ?? '');
    _bioCtrl = TextEditingController(
        text: widget.currentProfile['bio'] as String? ?? '');
    _selectedSports =
        List<String>.from(widget.currentProfile['sports'] as List? ?? []);
    _selectedLevel =
        widget.currentProfile['level'] as String? ?? 'Intermédiaire';
    _selectedPassions =
        List<String>.from(widget.currentProfile['passions'] as List? ?? []);
    _lookingFor =
        widget.currentProfile['lookingFor'] as String? ?? 'Amitié sportive';
    _heightCtrl = TextEditingController(
      text: widget.currentProfile['height'] != null
          ? widget.currentProfile['height'].toString()
          : '',
    );
    _ethnicityCtrl = TextEditingController(
      text: widget.currentProfile['ethnicity'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    _heightCtrl.dispose();
    _ethnicityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSports.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un sport'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) throw Exception('Non connecté');

      final heightText = _heightCtrl.text.trim();
      final ethnicityText = _ethnicityCtrl.text.trim();

      await _profileService.createOrUpdateProfile(
        userId: userId,
        name: _nameCtrl.text.trim(),
        age: int.parse(_ageCtrl.text.trim()),
        location: _locationCtrl.text.trim(),
        sports: _selectedSports,
        level: _selectedLevel,
        bio: _bioCtrl.text.trim(),
        imageUrl: widget.currentProfile['image'] as String?,
        passions: _selectedPassions,
        lookingFor: _lookingFor,
        height: heightText.isEmpty ? null : int.tryParse(heightText),
        ethnicity: ethnicityText.isEmpty ? null : ethnicityText,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Modifier mon profil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Sauvegarder',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection(
              title: 'Informations personnelles',
              icon: Icons.person_outline,
              children: [
                _buildTextField(
                  controller: _nameCtrl,
                  label: 'Prénom',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _ageCtrl,
                  label: 'Âge',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final age = int.tryParse(v ?? '');
                    if (age == null || age < 18 || age > 99) {
                      return 'Âge invalide (18–99)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _locationCtrl,
                  label: 'Ville',
                  icon: Icons.location_on_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Sports pratiqués',
              icon: Icons.emoji_events_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allSports.map((sport) {
                    final selected = _selectedSports.contains(sport);
                    return FilterChip(
                      label: Text(sport),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedSports.add(sport);
                          } else {
                            _selectedSports.remove(sport);
                          }
                        });
                      },
                      selectedColor:
                          const Color(0xFF2563EB).withValues(alpha: 0.12),
                      checkmarkColor: const Color(0xFF2563EB),
                      labelStyle: TextStyle(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : Colors.black87,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Niveau sportif',
              icon: Icons.bar_chart,
              children: _levels.map((level) {
                return RadioListTile<String>(
                  title: Text(level),
                  value: level,
                  groupValue: _selectedLevel,
                  onChanged: (v) => setState(() => _selectedLevel = v!),
                  activeColor: const Color(0xFF2563EB),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Je cherche',
              icon: Icons.favorite_outline,
              children: _lookingForOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _lookingFor,
                  onChanged: (v) => setState(() => _lookingFor = v!),
                  activeColor: const Color(0xFF2563EB),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Passions',
              icon: Icons.interests_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _allPassions.map((passion) {
                    final selected = _selectedPassions.contains(passion);
                    return FilterChip(
                      label: Text(passion),
                      selected: selected,
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedPassions.add(passion);
                          } else {
                            _selectedPassions.remove(passion);
                          }
                        });
                      },
                      selectedColor: Colors.green.shade50,
                      checkmarkColor: Colors.green.shade700,
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.green.shade700
                            : Colors.black87,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Physique (optionnel)',
              icon: Icons.accessibility_new_outlined,
              children: [
                _buildTextField(
                  controller: _heightCtrl,
                  label: 'Taille (cm)',
                  icon: Icons.height,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _ethnicityCtrl,
                  label: 'Origine / Ethnie',
                  icon: Icons.public_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'À propos de moi',
              icon: Icons.edit_note,
              children: [
                TextFormField(
                  controller: _bioCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText:
                        'Parlez de vous, de vos objectifs sportifs...',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterStyle: TextStyle(color: Colors.grey.shade500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }
}
