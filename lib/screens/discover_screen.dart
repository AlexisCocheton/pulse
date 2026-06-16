import 'dart:math';

import 'package:flutter/material.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../services/matching_service.dart';
import '../services/location_service.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  int _currentIndex = 0;
  bool _showInfo = false;
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final MatchingService _matchingService = MatchingService();
  List<Map<String, dynamic>> profiles = [];
  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  double _dragOffset = 0;
  double _maxDistance = 5.0;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Récupérer l'userId de l'utilisateur connecté
      _currentUserId = await _authService.getCurrentUserId();

      if (_currentUserId == null) {
        setState(() {
          _error = 'Vous devez créer un profil d\'abord';
          _isLoading = false;
        });
        return;
      }

      // Récupérer la distance maximale depuis Firestore
      final userProfile = await _profileService.getProfile(_currentUserId!);
      if (userProfile != null) {
        _maxDistance = ((userProfile['maxDistance'] as num?) ?? 5.0).toDouble();
      }

      // Essayer de charger les profils depuis le backend API
      List<Map<String, dynamic>> loadedProfiles = [];
      try {
        loadedProfiles = await _matchingService.getMatchCandidates(
          userId: _currentUserId!,
          maxDistance: _maxDistance,
          limit: 20,
        );
      } catch (apiError) {
        // Fallback : charger les profils découvrables localement
        loadedProfiles = await _profileService.getDiscoverableProfiles(_currentUserId!);

        // Filtrer par distance si on a les coordonnées
        if (userProfile != null && userProfile['location_coords'] != null) {
          final userLat = userProfile['location_coords']['latitude'] as double?;
          final userLong = userProfile['location_coords']['longitude'] as double?;

          if (userLat != null && userLong != null) {
            final locationService = LocationService();
            loadedProfiles = loadedProfiles.where((profile) {
              final targetCoords = profile['location_coords'] as Map?;
              if (targetCoords == null) return false;

              final targetLat = targetCoords['latitude'] as double?;
              final targetLong = targetCoords['longitude'] as double?;

              if (targetLat == null || targetLong == null) return false;

              final distance = locationService.calculateDistance(
                userLat, userLong, targetLat, targetLong
              );
              return distance <= _maxDistance;
            }).toList();
          }
        }
      }

      final profilesWithDistance = loadedProfiles.map((profile) {
        // Calculer la distance réelle si on a les coordonnées
        String distance = 'N/A';
        if (userProfile != null && userProfile['location_coords'] != null) {
          final userCoords = userProfile['location_coords'] as Map?;
          final targetCoords = profile['location_coords'] as Map?;

          if (userCoords != null && targetCoords != null) {
            final userLat = userCoords['latitude'] as double?;
            final userLong = userCoords['longitude'] as double?;
            final targetLat = targetCoords['latitude'] as double?;
            final targetLong = targetCoords['longitude'] as double?;

            if (userLat != null && userLong != null && targetLat != null && targetLong != null) {
              final locationService = LocationService();
              final dist = locationService.calculateDistance(
                userLat, userLong, targetLat, targetLong
              );
              distance = '${dist.toStringAsFixed(1)} km';
            }
          }
        }

        return {
          ...profile,
          'distance': distance,
        };
      }).toList();

      setState(() {
        profiles = profilesWithDistance;
        _isLoading = false;
        _currentIndex = 0;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des profils: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(String action) async {
    if (profiles.isEmpty || _currentUserId == null) return;
    
    final currentProfile = profiles[_currentIndex];
    final targetUserId = currentProfile['id'] as String;

    try {
      String interactionType;
      switch (action) {
        case 'pass':
          interactionType = 'pass';
          break;
        case 'super':
          interactionType = 'super_like';
          break;
        case 'like':
        default:
          interactionType = 'like';
          break;
      }

      // Enregistrer l'interaction
      await _profileService.addInteraction(
        fromUserId: _currentUserId!,
        toUserId: targetUserId,
        type: interactionType,
      );

      // Si c'est un like ou super like, vérifier si c'est un match
      if (interactionType == 'like' || interactionType == 'super_like') {
        final isMatch = await _profileService.checkMatch(_currentUserId!, targetUserId);
        if (isMatch) {
          // Créer le match
          await _profileService.createMatch(_currentUserId!, targetUserId);
          
          if (!mounted) return;
          
          // Afficher une notification de match
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.favorite, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🎉 C\'est un match ! Vous vous êtes aimés !',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.pink,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      // Passer au profil suivant
      setState(() {
        _showInfo = false;
        _dragOffset = 0;
      });

      // Retirer le profil actuel de la liste
      if (profiles.length > 1) {
        setState(() {
          profiles.removeAt(_currentIndex);
          _currentIndex = 0;
        });
      } else {
        // Plus de profils disponibles
        setState(() {
          profiles.clear();
          _currentIndex = 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Découvrir',
            style: TextStyle(color: Colors.black87),
          ),
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Image.asset('assets/logo_v2.png', width: 32, height: 32),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Découvrir',
            style: TextStyle(color: Colors.black87),
          ),
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Image.asset('assets/logo_v2.png', width: 32, height: 32),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadProfiles,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = profiles.isNotEmpty ? profiles[_currentIndex] : null;

    if (profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text(
            'Découvrir',
            style: TextStyle(color: Colors.black87),
          ),
          centerTitle: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Image.asset('assets/logo_v2.png', width: 32, height: 32),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun profil disponible',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Créez votre profil pour commencer à découvrir des partenaires !',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sports = (profile['sports'] as List<dynamic>?)
            ?.map((s) => s.toString())
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Découvrir',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('assets/logo_v2.png', width: 32, height: 32),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive: adapter la hauteur selon l'écran
                    final screenHeight = MediaQuery.of(context).size.height;
                    final maxHeight = min(constraints.maxHeight, screenHeight * 0.65);
                    final minHeight = min(400.0, screenHeight * 0.5);
                    final cardHeight = max(maxHeight, minHeight);
                    
                    return GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        setState(() => _dragOffset += details.delta.dx);
                      },
                      onHorizontalDragEnd: (details) {
                        final v = details.primaryVelocity ?? 0;
                        if (_dragOffset > 80 || v > 400) {
                          _handleAction('like');
                        } else if (_dragOffset < -80 || v < -400) {
                          _handleAction('pass');
                        }
                        setState(() => _dragOffset = 0);
                      },
                      child: Transform.rotate(
                        angle: _dragOffset / 1000,
                        alignment: Alignment.bottomCenter,
                        child: Transform.translate(
                          offset: Offset(_dragOffset, _dragOffset.abs() * 0.05),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            width: double.infinity,
                            height: cardHeight,
                            child: Stack(
                              children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.network(
                                        profile['image'] as String? ?? 'https://images.unsplash.com/photo-1658702041515-18275b138fda?auto=format&fit=crop&w=800&q=80',
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.person, size: 80, color: Colors.grey),
                                        ),
                                      ),
                                      Container(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black87,
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 16,
                                        right: 16,
                                        child: CircleAvatar(
                                          backgroundColor:
                                              Colors.white.withValues(alpha: 0.2),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.info_outline,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              setState(
                                                  () => _showInfo = !_showInfo);
                                            },
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        left: 16,
                                        right: 16,
                                        bottom: 16,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    '${profile['name']}, ${profile['age']}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: max(20, MediaQuery.of(context).size.width * 0.055),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.star,
                                                  size: 18,
                                                  color: Colors.amber,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_outlined,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    '${profile['location']} • ${profile['distance']}',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: max(12, MediaQuery.of(context).size.width * 0.033),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                ...sports.map(
                                                  (s) => Chip(
                                                    label: Text(s),
                                                    backgroundColor: Colors
                                                        .black
                                                        .withValues(alpha: 0.55),
                                                    labelStyle:
                                                        const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                    side: BorderSide.none,
                                                    padding: EdgeInsets.zero,
                                                  ),
                                                ),
                                                if (profile['level'] != null)
                                                Chip(
                                                  label: Text(
                                                    profile['level'] as String,
                                                  ),
                                                  backgroundColor:
                                                      colorScheme.secondary,
                                                  labelStyle: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
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
                                // Bio rétractable
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: _showInfo ? cardHeight * 0.4 : 0,
                                  padding: const EdgeInsets.all(16),
                                  alignment: Alignment.topLeft,
                                  child: SingleChildScrollView(
                                    child: Text(
                                      profile['bio'] as String? ?? '',
                                      style: TextStyle(
                                        fontSize: max(13, MediaQuery.of(context).size.width * 0.037),
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                              if (_dragOffset > 20)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      color: Colors.green.withValues(alpha: 0.45),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.favorite, color: Colors.white, size: 80),
                                    ),
                                  ),
                                ),
                              if (_dragOffset < -20)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      color: Colors.red.withValues(alpha: 0.45),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.close, color: Colors.white, size: 80),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: max(16, MediaQuery.of(context).size.width * 0.06),
              vertical: 16,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CircleActionButton(
                      size: max(56, MediaQuery.of(context).size.width * 0.15),
                      background: Colors.grey.shade100,
                      icon: Icons.close,
                      iconColor: Colors.grey.shade700,
                      onTap: () => _handleAction('pass'),
                    ),
                    _CircleActionButton(
                      size: max(50, MediaQuery.of(context).size.width * 0.13),
                      background: Colors.white,
                      borderColor: colorScheme.primary,
                      icon: Icons.star,
                      iconColor: colorScheme.primary,
                      onTap: () => _handleAction('super'),
                    ),
                    _CircleActionButton(
                      size: max(64, MediaQuery.of(context).size.width * 0.17),
                      background: colorScheme.secondary,
                      icon: Icons.favorite,
                      iconColor: Colors.white,
                      onTap: () => _handleAction('like'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  profiles.isNotEmpty
                      ? '${_currentIndex + 1} / ${profiles.length}'
                      : '0 / 0',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final double size;
  final Color background;
  final Color? borderColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.size,
    required this.background,
    this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: borderColor != null
              ? Border.all(color: borderColor!, width: 2)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: size * 0.45),
      ),
    );
  }
}

