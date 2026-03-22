import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _isVisible = true;
  bool _showAge = true;
  bool _showLocation = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(_uid)
        .get();
    final data = doc.data() ?? {};
    setState(() {
      _isVisible = (data['isVisible'] as bool?) ?? true;
      _showAge = (data['showAge'] as bool?) ?? true;
      _showLocation = (data['showLocation'] as bool?) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_uid == null) return;
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('profiles').doc(_uid).set({
      'isVisible': _isVisible,
      'showAge': _showAge,
      'showLocation': _showLocation,
    }, SetOptions(merge: true));
    setState(() => _isSaving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préférences sauvegardées'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Confidentialité'),
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
                        color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  title: 'Visibilité du profil',
                  icon: Icons.visibility_outlined,
                  children: [
                    SwitchListTile(
                      title: const Text('Profil visible'),
                      subtitle: const Text(
                          'Votre profil apparaît dans la découverte d\'autres utilisateurs'),
                      value: _isVisible,
                      onChanged: (v) => setState(() => _isVisible = v),
                      activeColor: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Informations affichées',
                  icon: Icons.person_outline,
                  children: [
                    SwitchListTile(
                      title: const Text('Afficher mon âge'),
                      subtitle: const Text(
                          'Votre âge est visible sur votre profil public'),
                      value: _showAge,
                      onChanged: (v) => setState(() => _showAge = v),
                      activeColor: const Color(0xFF2563EB),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Afficher ma ville'),
                      subtitle: const Text(
                          'Votre ville est visible sur votre profil public'),
                      value: _showLocation,
                      onChanged: (v) => setState(() => _showLocation = v),
                      activeColor: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Données personnelles',
                  icon: Icons.shield_outlined,
                  children: [
                    ListTile(
                      title: const Text('Supprimer mon compte'),
                      subtitle: const Text(
                          'Supprime définitivement votre profil et vos données'),
                      leading: const Icon(Icons.delete_forever_outlined,
                          color: Colors.red),
                      onTap: _showDeleteDialog,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
            'Cette action est irréversible. Toutes vos données seront supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: implement full account deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Contactez le support pour supprimer votre compte.')),
              );
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}
