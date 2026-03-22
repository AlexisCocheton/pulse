import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasPermission = false;

  bool _notifLikes = true;
  bool _notifMessages = true;
  bool _notifMatches = true;

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
    final perm = await NotificationService().hasPermission;
    setState(() {
      _notifLikes = (data['notifLikes'] as bool?) ?? true;
      _notifMessages = (data['notifMessages'] as bool?) ?? true;
      _notifMatches = (data['notifMatches'] as bool?) ?? true;
      _hasPermission = perm;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_uid == null) return;
    setState(() => _isSaving = true);
    await FirebaseFirestore.instance.collection('profiles').doc(_uid).set({
      'notifLikes': _notifLikes,
      'notifMessages': _notifMessages,
      'notifMatches': _notifMatches,
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
        title: const Text('Notifications'),
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
                if (!_hasPermission)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Les notifications système sont désactivées. Activez-les dans les paramètres de votre téléphone pour recevoir des alertes.',
                            style: TextStyle(
                                color: Colors.orange.shade800, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                _buildSection(
                  title: 'Types de notifications',
                  icon: Icons.notifications_outlined,
                  children: [
                    SwitchListTile(
                      title: const Text('Nouveaux likes'),
                      subtitle:
                          const Text('Quand quelqu\'un aime votre profil'),
                      value: _notifLikes,
                      onChanged: (v) => setState(() => _notifLikes = v),
                      activeColor: const Color(0xFF2563EB),
                      secondary: const Icon(Icons.favorite_outline,
                          color: Colors.pinkAccent),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Nouveaux messages'),
                      subtitle: const Text('Quand vous recevez un message'),
                      value: _notifMessages,
                      onChanged: (v) => setState(() => _notifMessages = v),
                      activeColor: const Color(0xFF2563EB),
                      secondary: const Icon(Icons.chat_bubble_outline,
                          color: Color(0xFF2563EB)),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Nouveaux matchs'),
                      subtitle:
                          const Text('Quand vous obtenez un match mutuel'),
                      value: _notifMatches,
                      onChanged: (v) => setState(() => _notifMatches = v),
                      activeColor: const Color(0xFF2563EB),
                      secondary: Icon(Icons.star_outline,
                          color: Colors.amber.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'À propos',
                  icon: Icons.info_outline,
                  children: [
                    ListTile(
                      title: const Text('Notifications push'),
                      subtitle: const Text(
                          'Les notifications arrivent même quand l\'application est fermée. Requiert Firebase Cloud Functions pour l\'envoi automatique.'),
                      leading: Icon(Icons.cloud_outlined,
                          color: Colors.grey.shade500),
                    ),
                  ],
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
