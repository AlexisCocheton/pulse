import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

const _reportReasons = [
  'Faux profil',
  'Comportement inapproprié',
  'Harcèlement',
  'Contenu offensant',
  'Autre',
];

class LikesScreen extends StatefulWidget {
  const LikesScreen({super.key});

  @override
  State<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen>
    with SingleTickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  late TabController _tabController;

  String? _currentUserId;
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _receivedLikes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showMatchOptions(Map<String, dynamic> profile) async {
    final matchId = profile['id'] as String;
    final matchName = profile['name'] as String? ?? '';

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                matchName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading:
                  const Icon(Icons.flag_outlined, color: Colors.orange),
              title: const Text('Signaler ce profil'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(matchId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.heart_broken_outlined,
                  color: Colors.red),
              title: const Text('Se désassocier',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showUnmatchDialog(matchId, matchName);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportDialog(String toUserId) async {
    String? selectedReason;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Signaler ce profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _reportReasons
                .map((r) => RadioListTile<String>(
                      title: Text(r),
                      value: r,
                      groupValue: selectedReason,
                      onChanged: (v) =>
                          setDialogState(() => selectedReason = v),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(ctx);
                      try {
                        await _profileService.reportUser(
                          fromUserId: _currentUserId!,
                          toUserId: toUserId,
                          reason: selectedReason!,
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Signalement envoyé')),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erreur : $e'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
              child: const Text('Signaler',
                  style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUnmatchDialog(
      String otherUserId, String otherName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se désassocier'),
        content: Text(
          'Voulez-vous vous désassocier de $otherName ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Se désassocier',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _profileService.unmatch(_currentUserId!, otherUserId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Désassocié avec succès')),
        );
        _loadData();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    _currentUserId = await _authService.getCurrentUserId();
    if (_currentUserId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final matches = await _profileService.getMatches(_currentUserId!);
    final matchIds = matches.map((m) => m['id'] as String).toSet();

    final likesReceived =
        await _profileService.getLikesReceived(_currentUserId!);
    final nonMutualLikes =
        likesReceived.where((l) => !matchIds.contains(l['id'])).toList();

    setState(() {
      _matches = matches;
      _receivedLikes = nonMutualLikes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Mes Likes',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('assets/logo_v2.png', width: 32, height: 32),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          tabs: [
            Tab(text: 'Matchs (${_matches.length})'),
            Tab(text: 'Reçus (${_receivedLikes.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMatchesGrid(),
                _buildReceivedLikesGrid(),
              ],
            ),
    );
  }

  Widget _buildMatchesGrid() {
    if (_matches.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        message: 'Aucun match pour l\'instant',
        subMessage: 'Continuez à swiper pour trouver vos partenaires sportifs !',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          final profile = _matches[index];
          final sports =
              (profile['sports'] as List<dynamic>?)?.cast<String>() ?? [];
          return _LikeCard(
            name: profile['name'] as String? ?? '',
            age: profile['age'] as int? ?? 0,
            image: profile['image'] as String? ?? '',
            location: profile['location'] as String? ?? '',
            sports: sports,
            highlighted: true,
            accentColor: Theme.of(context).colorScheme.secondary,
            badgeIcon: Icons.favorite,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  currentUserId: _currentUserId!,
                  otherUserId: profile['id'] as String,
                  otherUserName: profile['name'] as String? ?? '',
                  otherUserImage: profile['image'] as String? ?? '',
                  otherUserAge: profile['age'] as int? ?? 0,
                ),
              ),
            ),
            onLongPress: () => _showMatchOptions(profile),
          );
        },
      ),
    );
  }

  Widget _buildReceivedLikesGrid() {
    if (_receivedLikes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.thumb_up_off_alt,
        message: 'Personne ne vous a encore liké',
        subMessage: 'Complétez votre profil pour attirer plus de partenaires !',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.8,
        ),
        itemCount: _receivedLikes.length,
        itemBuilder: (context, index) {
          final profile = _receivedLikes[index];
          final sports =
              (profile['sports'] as List<dynamic>?)?.cast<String>() ?? [];
          return _LikeCard(
            name: profile['name'] as String? ?? '',
            age: profile['age'] as int? ?? 0,
            image: profile['image'] as String? ?? '',
            location: profile['location'] as String? ?? '',
            sports: sports,
            highlighted: false,
            accentColor: Theme.of(context).colorScheme.secondary,
            badgeIcon: Icons.star,
            onTap: null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  final String name;
  final int age;
  final String image;
  final String location;
  final List<String> sports;
  final bool highlighted;
  final Color accentColor;
  final IconData badgeIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _LikeCard({
    required this.name,
    required this.age,
    required this.image,
    required this.location,
    required this.sports,
    required this.highlighted,
    required this.accentColor,
    required this.badgeIcon,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
          border: highlighted
              ? Border.all(color: accentColor.withValues(alpha: 0.4), width: 2)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  image.isNotEmpty
                      ? Image.network(image, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.person,
                              size: 48, color: Colors.grey),
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          highlighted ? accentColor : Colors.white54,
                      child: Icon(
                        badgeIcon,
                        size: 15,
                        color: highlighted ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  if (highlighted)
                    Positioned(
                      bottom: 36,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Appuyer pour chatter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$name, $age',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (location.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  location,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: sports.take(2).map((s) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: highlighted
                          ? accentColor.withValues(alpha: 0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: highlighted
                            ? accentColor.withValues(alpha: 0.4)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        color:
                            highlighted ? accentColor : Colors.grey.shade800,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
