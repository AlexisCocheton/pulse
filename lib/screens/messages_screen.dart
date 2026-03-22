import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final ChatService _chatService = ChatService();
  final ProfileService _profileService = ProfileService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Non connecté')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Messages',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset('assets/logo_v2.png', width: 32, height: 32),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Rechercher une conversation...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatService.getConversations(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Impossible de charger les conversations',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final users =
                  (conv['users'] as List<dynamic>?)?.cast<String>() ?? [];
              final otherUserId = users.firstWhere(
                (id) => id != _currentUserId,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              final unreadKey = 'unreadCount_$_currentUserId';
              final unread = (conv[unreadKey] as int?) ?? 0;
              final lastMessage = conv['lastMessage'] as String? ?? '';
              final lastSenderId = conv['lastSenderId'] as String?;
              final isLastMessageMine = lastSenderId == _currentUserId;

              return FutureBuilder<Map<String, dynamic>?>(
                future: _profileService.getProfile(otherUserId),
                builder: (context, profileSnapshot) {
                  final profile = profileSnapshot.data;
                  final name =
                      profile?['name'] as String? ?? 'Utilisateur';
                  final age = profile?['age'] as int? ?? 0;
                  final image = profile?['image'] as String? ?? '';
                  final sports =
                      (profile?['sports'] as List<dynamic>?)?.cast<String>() ??
                          [];
                  final sport =
                      sports.isNotEmpty ? sports.first : '';

                  if (_searchQuery.isNotEmpty &&
                      !name.toLowerCase().contains(_searchQuery)) {
                    return const SizedBox.shrink();
                  }

                  final timeLabel =
                      _formatConvTime(conv['lastMessageTime']);

                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            currentUserId: _currentUserId!,
                            otherUserId: otherUserId,
                            otherUserName: name,
                            otherUserImage: image,
                            otherUserAge: age,
                          ),
                        ),
                      );
                    },
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: image.isNotEmpty
                              ? NetworkImage(image)
                              : null,
                          child: image.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.redAccent,
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$name, $age',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (isLastMessageMine)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.done_all,
                                  size: 14,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: unread > 0
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (sport.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            sport,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    tileColor: Colors.white,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatConvTime(dynamic timestamp) {
    if (timestamp == null) return '';
    final dt = (timestamp as Timestamp).toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${dt.day}/${dt.month}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune conversation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Matchez avec quelqu\'un pour commencer à discuter !',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
