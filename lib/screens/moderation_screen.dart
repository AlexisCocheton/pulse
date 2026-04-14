import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../services/seed_service.dart';
import '../services/moderation_service.dart';

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = ModerationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        leading: const SizedBox.shrink(),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 22),
            SizedBox(width: 8),
            Text('Modération', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Créer profils de test',
            onPressed: _seedProfiles,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Quitter',
            onPressed: _confirmLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            // Onglet Photos avec badge
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(child: Text('Photos', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  StreamBuilder<int>(
                    stream: _service.pendingPhotosCount,
                    builder: (_, snap) {
                      final n = snap.data ?? 0;
                      if (n == 0) return const SizedBox.shrink();
                      return _Badge(n);
                    },
                  ),
                ],
              ),
            ),
            // Onglet Signalements avec badge
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Flexible(child: Text('Rapports', style: TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  StreamBuilder<int>(
                    stream: _service.pendingReportsCount,
                    builder: (_, snap) {
                      final n = snap.data ?? 0;
                      if (n == 0) return const SizedBox.shrink();
                      return _Badge(n);
                    },
                  ),
                ],
              ),
            ),
            const Tab(child: Text('Profils', style: TextStyle(fontSize: 12))),
            const Tab(child: Text('Journal', style: TextStyle(fontSize: 12))),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatsHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPhotosTab(),
                _buildReportsTab(),
                _buildProfilesTab(),
                _buildJournalTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats header ───────────────────────────────────────────────────────────

  Widget _buildStatsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _StreamStatChip(
            stream: _service.pendingPhotosCount,
            icon: Icons.photo_camera_outlined,
            label: 'Photos',
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _StreamStatChip(
            stream: _service.pendingReportsCount,
            icon: Icons.flag_outlined,
            label: 'Signalements',
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _StreamStatChip(
            stream: _service.suspendedCount,
            icon: Icons.block,
            label: 'Suspendus',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  // ── Onglet Photos (Safe Search) ────────────────────────────────────────────

  Widget _buildPhotosTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.flaggedPhotos,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final photos = snap.data ?? [];
        if (photos.isEmpty) {
          return _EmptyState(
            icon: Icons.check_circle_outline,
            message: 'Aucune photo en attente de revue.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: photos.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _SectionHeader(
                title: 'Photos à analyser (${photos.length})',
                color: Colors.purple,
              );
            }
            return _PhotoReportCard(
              photo: photos[i - 1],
              onApprove: () => _approvePhoto(photos[i - 1]),
              onReject: () => _showRejectPhotoDialog(photos[i - 1]),
            );
          },
        );
      },
    );
  }

  void _approvePhoto(Map<String, dynamic> photo) async {
    try {
      await _service.approvePhoto(photo['userId'] as String);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo approuvée'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRejectPhotoDialog(Map<String, dynamic> photo) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter cette photo'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Raison du rejet (optionnel)',
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _service.rejectPhoto(
                  photo['userId'] as String,
                  ctrl.text.trim().isEmpty ? 'Non conforme' : ctrl.text.trim(),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Photo supprimée du profil'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Helpers actions ────────────────────────────────────────────────────────

  /// Exécute une action async et affiche un snackbar en cas d'erreur.
  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmSuspendFromReport(Map<String, dynamic> report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Suspendre cet utilisateur ?'),
        content: Text('L\'utilisateur ${report['toUserId'] ?? ''} sera suspendu et retiré de la découverte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Suspendre', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runAction(() => _service.suspendFromReport(report['id'] as String, report['toUserId'] as String));
    }
  }

  Future<void> _confirmToggleProfile(Map<String, dynamic> profile) async {
    final suspended = (profile['suspended'] as bool?) == true;
    final name = profile['name'] as String? ?? profile['id'] as String? ?? '—';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(suspended ? 'Réactiver $name ?' : 'Suspendre $name ?'),
        content: Text(suspended
            ? 'Le profil sera à nouveau visible dans la découverte.'
            : 'Le profil sera masqué de la découverte.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: suspended ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              suspended ? 'Réactiver' : 'Suspendre',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _runAction(() => suspended
          ? _service.restoreProfile(profile['id'] as String)
          : _service.suspendProfile(profile['id'] as String));
    }
  }

  // ── Onglet Signalements ────────────────────────────────────────────────────

  Widget _buildReportsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.userReports,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final reports = snap.data ?? [];
        final pending = reports.where((r) => r['status'] == null || r['status'] == 'pending').toList();
        final resolved = reports.where((r) => r['status'] != null && r['status'] != 'pending').toList();

        if (reports.isEmpty) {
          return _EmptyState(
            icon: Icons.flag_outlined,
            message: 'Aucun signalement pour le moment.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (pending.isNotEmpty) ...[
              _SectionHeader(
                title: 'En attente (${pending.length})',
                color: Colors.orange,
              ),
              const SizedBox(height: 8),
              ...pending.map((r) => _ReportCard(
                    report: r,
                    onDismiss: () => _runAction(() => _service.dismissReport(r['id'] as String, r['toUserId'] as String)),
                    onWarn: () => _runAction(() => _service.warnUser(r['id'] as String, r['toUserId'] as String)),
                    onSuspend: () => _confirmSuspendFromReport(r),
                  )),
            ],
            if (resolved.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionHeader(title: 'Traités (${resolved.length})', color: Colors.grey),
              const SizedBox(height: 8),
              ...resolved.map((r) => _ResolvedReportCard(report: r)),
            ],
          ],
        );
      },
    );
  }

  // ── Onglet Profils ─────────────────────────────────────────────────────────

  Widget _buildProfilesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.allProfiles,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final profiles = snap.data ?? [];
        if (profiles.isEmpty) {
          return _EmptyState(
            icon: Icons.people_outline,
            message: 'Aucun profil trouvé.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: profiles.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _SectionHeader(title: 'Tous les profils (${profiles.length})');
            }
            final p = profiles[i - 1];
            return _ProfileCard(
              profile: p,
              onToggle: () => _confirmToggleProfile(p),
            );
          },
        );
      },
    );
  }

  // ── Onglet Journal ─────────────────────────────────────────────────────────

  Widget _buildJournalTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.activityLogs,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return _EmptyState(
            icon: Icons.history,
            message: 'Aucune action enregistrée.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            if (i == 0) {
              return _SectionHeader(title: 'Journal des actions (${logs.length})');
            }
            return _LogCard(log: logs[i - 1]);
          },
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _seedProfiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer des profils de test'),
        content: Text(
          'Cela va créer ${SeedService().profileCount} profils fictifs dans Firestore.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await SeedService().seedProfiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${SeedService().profileCount} profils créés'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Quitter l\'espace d\'administration ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}

// ── Widgets ────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  const _Badge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StreamStatChip extends StatelessWidget {
  final Stream<int> stream;
  final IconData icon;
  final String label;
  final Color color;

  const _StreamStatChip({
    required this.stream,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<int>(
        stream: stream,
        builder: (_, snap) {
          final value = snap.data ?? 0;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                ),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionHeader({required this.title, this.color = Colors.black87});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

// ── Carte photo Safe Search ───────────────────────────────────────────────────

class _PhotoReportCard extends StatelessWidget {
  final Map<String, dynamic> photo;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PhotoReportCard({
    required this.photo,
    required this.onApprove,
    required this.onReject,
  });

  Color _levelColor(String? level) {
    switch (level) {
      case 'VERY_LIKELY':
      case 'LIKELY':
        return Colors.red;
      case 'POSSIBLE':
        return Colors.orange;
      case 'UNLIKELY':
      case 'VERY_UNLIKELY':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _levelBadge(String label, String? level) {
    final color = _levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$label : ${level ?? '—'}',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = photo['imageUrl'] as String?;
    final decision = photo['autoDecision'] as String? ?? 'pending';
    final reason = photo['reason'] as String?;
    final isError = decision == 'error';

    Color borderColor;
    String decisionLabel;
    switch (decision) {
      case 'flagged':
        borderColor = Colors.orange;
        decisionLabel = 'Signalé auto';
        break;
      case 'rejected':
        borderColor = Colors.red;
        decisionLabel = 'Rejeté auto';
        break;
      case 'error':
        borderColor = Colors.grey;
        decisionLabel = 'Erreur d\'analyse';
        break;
      default:
        borderColor = Colors.blue.shade200;
        decisionLabel = 'Approuvé auto';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Miniature photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _photoPlaceholder(),
                        )
                      : _photoPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Décision automatique
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          decisionLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: borderColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'User : ${photo['userId'] ?? '—'}',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reason != null && reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (!isError) ...[
              const SizedBox(height: 12),
              // Scores Safe Search
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _levelBadge('Adult', photo['adult'] as String?),
                  _levelBadge('Violence', photo['violence'] as String?),
                  _levelBadge('Racy', photo['racy'] as String?),
                  _levelBadge('Medical', photo['medical'] as String?),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approuver', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Rejeter', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: Colors.grey.shade200,
      child: Icon(Icons.person, color: Colors.grey.shade400, size: 36),
    );
  }
}

// ── Carte signalement utilisateur ─────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final VoidCallback onDismiss;
  final VoidCallback onWarn;
  final VoidCallback onSuspend;

  const _ReportCard({
    required this.report,
    required this.onDismiss,
    required this.onWarn,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    final reason = report['reason'] as String? ?? 'Raison non précisée';
    final timestamp = report['createdAt'] as Timestamp?;
    final timeLabel = timestamp != null ? _formatTime(timestamp.toDate()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header : user signalé + heure
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag, color: Colors.orange.shade700, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Signalé : ${report['toUserId'] ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Par : ${report['fromUserId'] ?? '—'}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (timeLabel.isNotEmpty)
                  Text(timeLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 10),
            // Raison
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(reason, style: const TextStyle(fontSize: 13, color: Colors.black87)),
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Ignorer', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onWarn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Avertir', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSuspend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Suspendre', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

class _ResolvedReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  const _ResolvedReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final status = report['status'] as String? ?? 'resolved';
    final reason = report['reason'] as String? ?? '';

    Color color;
    String label;
    switch (status) {
      case 'dismissed':
        color = Colors.green;
        label = 'Ignoré';
        break;
      case 'warned':
        color = Colors.orange;
        label = 'Averti';
        break;
      case 'suspended':
        color = Colors.red;
        label = 'Suspendu';
        break;
      default:
        color = Colors.grey;
        label = 'Traité';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['toUserId'] as String? ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (reason.isNotEmpty)
                  Text(reason, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ),
        ],
      ),
    );
  }
}

// ── Carte profil ──────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onToggle;

  const _ProfileCard({required this.profile, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final suspended = (profile['suspended'] as bool?) == true;
    final warned = (profile['warned'] as bool?) == true;
    final image = profile['image'] as String? ?? '';
    final sports = (profile['sports'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: suspended ? Colors.red.shade200 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                onBackgroundImageError: image.isNotEmpty ? (_, __) {} : null,
                child: image.isEmpty ? const Icon(Icons.person) : null,
              ),
              if (suspended)
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                    child: const Icon(Icons.block, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${profile['name'] ?? '—'}, ${profile['age'] ?? '?'} ans',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: suspended ? Colors.grey : Colors.black87,
                      ),
                    ),
                    if (warned) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.warning_amber, color: Colors.orange, size: 14),
                    ],
                  ],
                ),
                Text(
                  profile['location'] as String? ?? '',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (sports.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: sports.take(2).map((s) => Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(s, style: TextStyle(fontSize: 10, color: Colors.blue.shade700)),
                        )).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: suspended ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: suspended ? Colors.green.shade300 : Colors.red.shade300,
                ),
              ),
              child: Text(
                suspended ? 'Réactiver' : 'Suspendre',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: suspended ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carte journal ─────────────────────────────────────────────────────────────

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  const _LogCard({required this.log});

  static const _actionMeta = {
    'photo_approved':      (Icons.check_circle_outline, Colors.green,  'Photo approuvée'),
    'photo_rejected':      (Icons.no_photography,       Colors.red,    'Photo rejetée'),
    'photo_auto_rejected': (Icons.smart_toy_outlined,   Colors.red,    'Rejet automatique'),
    'report_dismissed':    (Icons.check_circle_outline, Colors.green,  'Signalement ignoré'),
    'profile_warned':      (Icons.warning_amber_outlined, Colors.orange, 'Avertissement'),
    'profile_suspended':   (Icons.block,                Colors.red,    'Profil suspendu'),
    'profile_restored':    (Icons.restore,              Colors.blue,   'Profil réactivé'),
  };

  @override
  Widget build(BuildContext context) {
    final action = log['action'] as String? ?? '';
    final meta = _actionMeta[action];
    final icon = meta?.$1 ?? Icons.info_outline;
    final color = meta?.$2 ?? Colors.grey;
    final label = meta?.$3 ?? action;

    final reason = log['reason'] as String?;
    final adminId = log['adminId'] as String? ?? '—';
    final timestamp = log['timestamp'] as Timestamp?;
    final timeLabel = timestamp != null ? _formatTime(timestamp.toDate()) : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  reason ?? 'Par : ${adminId == 'auto' ? 'Système' : adminId}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(timeLabel, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}
