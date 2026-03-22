import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import '../services/seed_service.dart';

// ── Données simulées ────────────────────────────────────────────────────────

class _Report {
  final String id;
  final String reportedName;
  final int reportedAge;
  final String reportedImage;
  final String reason;
  final int reportCount;
  final String timeAgo;
  _ModerationStatus status;

  _Report({
    required this.id,
    required this.reportedName,
    required this.reportedAge,
    required this.reportedImage,
    required this.reason,
    required this.reportCount,
    required this.timeAgo,
    this.status = _ModerationStatus.pending,
  });
}

class _ProfileEntry {
  final String id;
  final String name;
  final int age;
  final String image;
  final String location;
  final List<String> sports;
  _ModerationStatus status;

  _ProfileEntry({
    required this.id,
    required this.name,
    required this.age,
    required this.image,
    required this.location,
    required this.sports,
    this.status = _ModerationStatus.approved,
  });
}

class _ActivityLog {
  final String action;
  final String target;
  final String admin;
  final String timeAgo;
  final _ActivityType type;

  const _ActivityLog({
    required this.action,
    required this.target,
    required this.admin,
    required this.timeAgo,
    required this.type,
  });
}

enum _ModerationStatus { pending, approved, warned, suspended }

enum _ActivityType { approve, warn, suspend, restore }

// ── Écran principal de modération ───────────────────────────────────────────

class ModerationScreen extends StatefulWidget {
  const ModerationScreen({super.key});

  @override
  State<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends State<ModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // -- Données simulées --
  final List<_Report> _reports = [
    _Report(
      id: 'r1',
      reportedName: 'Thomas',
      reportedAge: 32,
      reportedImage:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      reason: 'Comportement inapproprié dans les messages',
      reportCount: 3,
      timeAgo: 'Il y a 1h',
    ),
    _Report(
      id: 'r2',
      reportedName: 'Sophie',
      reportedAge: 24,
      reportedImage:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      reason: 'Photo de profil non conforme',
      reportCount: 1,
      timeAgo: 'Il y a 3h',
    ),
    _Report(
      id: 'r3',
      reportedName: 'Kevin',
      reportedAge: 28,
      reportedImage:
          'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=200&q=80',
      reason: 'Faux profil — informations incorrectes',
      reportCount: 5,
      timeAgo: 'Il y a 6h',
    ),
    _Report(
      id: 'r4',
      reportedName: 'Léa',
      reportedAge: 21,
      reportedImage:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
      reason: 'Spam / messages commerciaux',
      reportCount: 2,
      timeAgo: 'Il y a 12h',
    ),
  ];

  final List<_ProfileEntry> _profiles = [
    _ProfileEntry(
      id: 'p1',
      name: 'Marie',
      age: 25,
      image:
          'https://images.unsplash.com/photo-1573113062125-2ccf3cbb67df?auto=format&fit=crop&w=200&q=80',
      location: 'Paris 15ème',
      sports: ['Tennis', 'Natation'],
      status: _ModerationStatus.approved,
    ),
    _ProfileEntry(
      id: 'p2',
      name: 'Lucas',
      age: 30,
      image:
          'https://images.unsplash.com/photo-1762025930827-9f1dda45aff8?auto=format&fit=crop&w=200&q=80',
      location: 'Paris 9ème',
      sports: ['Basketball', 'Course'],
      status: _ModerationStatus.approved,
    ),
    _ProfileEntry(
      id: 'p3',
      name: 'Thomas',
      age: 32,
      image:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
      location: 'Lyon',
      sports: ['Football', 'Fitness'],
      status: _ModerationStatus.pending,
    ),
    _ProfileEntry(
      id: 'p4',
      name: 'Kevin',
      age: 28,
      image:
          'https://images.unsplash.com/photo-1463453091185-61582044d556?auto=format&fit=crop&w=200&q=80',
      location: 'Marseille',
      sports: ['Course'],
      status: _ModerationStatus.suspended,
    ),
    _ProfileEntry(
      id: 'p5',
      name: 'Emma',
      age: 26,
      image:
          'https://images.unsplash.com/photo-1623171855411-3b686d975cf3?auto=format&fit=crop&w=200&q=80',
      location: 'Paris 12ème',
      sports: ['Yoga', 'Course'],
      status: _ModerationStatus.approved,
    ),
  ];

  final List<_ActivityLog> _activity = [
    _ActivityLog(
      action: 'Profil suspendu',
      target: 'Kevin (28 ans)',
      admin: 'admin@pulse.fr',
      timeAgo: 'Il y a 30 min',
      type: _ActivityType.suspend,
    ),
    _ActivityLog(
      action: 'Avertissement envoyé',
      target: 'Sophie (24 ans)',
      admin: 'admin@pulse.fr',
      timeAgo: 'Il y a 2h',
      type: _ActivityType.warn,
    ),
    _ActivityLog(
      action: 'Signalement ignoré',
      target: 'Marie (25 ans)',
      admin: 'admin@pulse.fr',
      timeAgo: 'Il y a 4h',
      type: _ActivityType.approve,
    ),
    _ActivityLog(
      action: 'Profil réactivé',
      target: 'Alexandre (29 ans)',
      admin: 'admin@pulse.fr',
      timeAgo: 'Il y a 1 jour',
      type: _ActivityType.restore,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _pendingCount =>
      _reports.where((r) => r.status == _ModerationStatus.pending).length;
  int get _suspendedCount =>
      _profiles.where((p) => p.status == _ModerationStatus.suspended).length;

  void _applyAction(_Report report, _ModerationStatus newStatus) {
    final actionLabel = switch (newStatus) {
      _ModerationStatus.approved => 'ignoré',
      _ModerationStatus.warned => 'averti',
      _ModerationStatus.suspended => 'suspendu',
      _ => 'traité',
    };

    setState(() {
      report.status = newStatus;
      if (newStatus == _ModerationStatus.suspended) {
        final profile = _profiles.where((p) => p.name == report.reportedName);
        if (profile.isNotEmpty) {
          profile.first.status = _ModerationStatus.suspended;
        }
      }
      _activity.insert(
        0,
        _ActivityLog(
          action: switch (newStatus) {
            _ModerationStatus.approved => 'Signalement ignoré',
            _ModerationStatus.warned => 'Avertissement envoyé',
            _ModerationStatus.suspended => 'Profil suspendu',
            _ => 'Action effectuée',
          },
          target: '${report.reportedName} (${report.reportedAge} ans)',
          admin: 'admin@pulse.fr',
          timeAgo: 'À l\'instant',
          type: switch (newStatus) {
            _ModerationStatus.approved => _ActivityType.approve,
            _ModerationStatus.warned => _ActivityType.warn,
            _ModerationStatus.suspended => _ActivityType.suspend,
            _ => _ActivityType.approve,
          },
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${report.reportedName} — $actionLabel'),
        backgroundColor: switch (newStatus) {
          _ModerationStatus.approved => Colors.green,
          _ModerationStatus.warned => Colors.orange,
          _ModerationStatus.suspended => Colors.red,
          _ => Colors.blue,
        },
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleProfileStatus(_ProfileEntry profile) {
    setState(() {
      if (profile.status == _ModerationStatus.suspended) {
        profile.status = _ModerationStatus.approved;
        _activity.insert(
          0,
          _ActivityLog(
            action: 'Profil réactivé',
            target: '${profile.name} (${profile.age} ans)',
            admin: 'admin@pulse.fr',
            timeAgo: 'À l\'instant',
            type: _ActivityType.restore,
          ),
        );
      } else {
        profile.status = _ModerationStatus.suspended;
        _activity.insert(
          0,
          _ActivityLog(
            action: 'Profil suspendu',
            target: '${profile.name} (${profile.age} ans)',
            admin: 'admin@pulse.fr',
            timeAgo: 'À l\'instant',
            type: _ActivityType.suspend,
          ),
        );
      }
    });
  }

  Future<void> _seedProfiles() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Créer des profils de test'),
        content: Text(
          'Cela va créer ${SeedService().profileCount} profils fictifs dans Firestore.\n\nVous pouvez les supprimer après vos tests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Créer',
                style: TextStyle(color: Colors.white)),
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
          content: Text(
              '✅ ${SeedService().profileCount} profils créés avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text(
          'Voulez-vous quitter l\'espace d\'administration ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Quitter',
              style: TextStyle(color: Colors.red),
            ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        leading: const SizedBox.shrink(),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Modération',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Signalements'),
                  if (_pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$_pendingCount',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Profils'),
            const Tab(text: 'Activité'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats header
          _buildStatsHeader(),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReportsTab(),
                _buildProfilesTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.flag_outlined,
            label: 'En attente',
            value: '$_pendingCount',
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.report_outlined,
            label: 'Signalements',
            value: '${_reports.length}',
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.block,
            label: 'Suspendus',
            value: '$_suspendedCount',
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final pending =
        _reports.where((r) => r.status == _ModerationStatus.pending).toList();
    final treated =
        _reports.where((r) => r.status != _ModerationStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _SectionHeader(
            title: 'En attente de traitement (${pending.length})',
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          ...pending.map((r) => _ReportCard(
                report: r,
                onIgnore: () => _applyAction(r, _ModerationStatus.approved),
                onWarn: () => _applyAction(r, _ModerationStatus.warned),
                onSuspend: () => _applyAction(r, _ModerationStatus.suspended),
              )),
        ],
        if (treated.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Déjà traités (${treated.length})',
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          ...treated.map((r) => _TreatedReportCard(report: r)),
        ],
        if (_reports.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Aucun signalement pour le moment.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfilesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Tous les profils (${_profiles.length})'),
        const SizedBox(height: 8),
        ..._profiles.map(
          (p) => _ProfileModerationCard(
            profile: p,
            onToggle: () => _toggleProfileStatus(p),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityTab() {
    if (_activity.isEmpty) {
      return const Center(
        child: Text(
          'Aucune activité récente.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Journal des actions récentes'),
        const SizedBox(height: 8),
        ..._activity.map((log) => _ActivityCard(log: log)),
      ],
    );
  }
}

// ── Widgets réutilisables ────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
    return Text(
      title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: color,
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _Report report;
  final VoidCallback onIgnore;
  final VoidCallback onWarn;
  final VoidCallback onSuspend;

  const _ReportCard({
    required this.report,
    required this.onIgnore,
    required this.onWarn,
    required this.onSuspend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info row
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(report.reportedImage),
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${report.reportedName}, ${report.reportedAge} ans',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        report.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flag, size: 12, color: Colors.red.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '${report.reportCount}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Reason
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                report.reason,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onIgnore,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        const Text('Avertir', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSuspend,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Suspendre',
                      style: TextStyle(fontSize: 12),
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
}

class _TreatedReportCard extends StatelessWidget {
  final _Report report;

  const _TreatedReportCard({required this.report});

  Color get _statusColor => switch (report.status) {
        _ModerationStatus.approved => Colors.green,
        _ModerationStatus.warned => Colors.orange,
        _ModerationStatus.suspended => Colors.red,
        _ => Colors.grey,
      };

  String get _statusLabel => switch (report.status) {
        _ModerationStatus.approved => 'Ignoré',
        _ModerationStatus.warned => 'Averti',
        _ModerationStatus.suspended => 'Suspendu',
        _ => 'Traité',
      };

  @override
  Widget build(BuildContext context) {
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
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(report.reportedImage),
            onBackgroundImageError: (_, __) {},
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${report.reportedName}, ${report.reportedAge} ans',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  report.reason,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileModerationCard extends StatelessWidget {
  final _ProfileEntry profile;
  final VoidCallback onToggle;

  const _ProfileModerationCard({
    required this.profile,
    required this.onToggle,
  });

  Color get _statusColor => switch (profile.status) {
        _ModerationStatus.approved => Colors.green,
        _ModerationStatus.suspended => Colors.red,
        _ModerationStatus.pending => Colors.orange,
        _ => Colors.grey,
      };

  String get _statusLabel => switch (profile.status) {
        _ModerationStatus.approved => 'Actif',
        _ModerationStatus.suspended => 'Suspendu',
        _ModerationStatus.pending => 'En attente',
        _ => 'Inconnu',
      };

  @override
  Widget build(BuildContext context) {
    final isSuspended = profile.status == _ModerationStatus.suspended;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSuspended ? Colors.red.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(profile.image),
                onBackgroundImageError: (_, __) {},
              ),
              if (isSuspended)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.name}, ${profile.age} ans',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isSuspended ? Colors.grey : Colors.black87,
                  ),
                ),
                Text(
                  profile.location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: profile.sports
                      .take(2)
                      .map(
                        (s) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSuspended
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSuspended
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    isSuspended ? 'Réactiver' : 'Suspendre',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSuspended ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityLog log;

  const _ActivityCard({required this.log});

  Color get _color => switch (log.type) {
        _ActivityType.approve => Colors.green,
        _ActivityType.warn => Colors.orange,
        _ActivityType.suspend => Colors.red,
        _ActivityType.restore => Colors.blue,
      };

  IconData get _icon => switch (log.type) {
        _ActivityType.approve => Icons.check_circle_outline,
        _ActivityType.warn => Icons.warning_amber_outlined,
        _ActivityType.suspend => Icons.block,
        _ActivityType.restore => Icons.restore,
      };

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.action,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  log.target,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                log.timeAgo,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 2),
              Text(
                log.admin,
                style: TextStyle(fontSize: 10, color: Colors.blue.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
