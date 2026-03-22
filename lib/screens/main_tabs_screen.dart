import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'discover_screen.dart';
import 'likes_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';

enum MainTab { discover, likes, messages, profile }

class MainTabsScreen extends StatefulWidget {
  const MainTabsScreen({super.key});

  @override
  State<MainTabsScreen> createState() => _MainTabsScreenState();
}

class _MainTabsScreenState extends State<MainTabsScreen> {
  MainTab _currentTab = MainTab.discover;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  Stream<int> get _unreadMessagesStream {
    if (_currentUserId == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('conversations')
        .where('users', arrayContains: _currentUserId!)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final unread =
            (doc.data()['unreadCount_$_currentUserId'] as int?) ?? 0;
        total += unread;
      }
      return total;
    });
  }

  Stream<int> get _newLikesStream {
    if (_currentUserId == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('interactions')
        .where('toUserId', isEqualTo: _currentUserId!)
        .where('type', whereIn: ['like', 'super_like'])
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  void _onTabSelected(int index) {
    setState(() => _currentTab = MainTab.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    switch (_currentTab) {
      case MainTab.discover:
        body = const DiscoverScreen();
        break;
      case MainTab.likes:
        body = const LikesScreen();
        break;
      case MainTab.messages:
        body = const MessagesScreen();
        break;
      case MainTab.profile:
        body = const ProfileScreen();
        break;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: StreamBuilder<int>(
        stream: _unreadMessagesStream,
        builder: (context, msgSnap) {
          final unread = msgSnap.data ?? 0;
          return StreamBuilder<int>(
            stream: _newLikesStream,
            builder: (context, likesSnap) {
              final likes = likesSnap.data ?? 0;
              return BottomNavigationBar(
                currentIndex: _currentTab.index,
                onTap: _onTabSelected,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: colorScheme.secondary,
                unselectedItemColor: Colors.grey,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore),
                    label: 'Découvrir',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: likes > 0,
                      label: Text('$likes'),
                      child: const Icon(Icons.favorite_border),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: likes > 0,
                      label: Text('$likes'),
                      child: const Icon(Icons.favorite),
                    ),
                    label: 'Likes',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.chat_bubble_outline),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: unread > 0,
                      label: Text('$unread'),
                      child: const Icon(Icons.chat_bubble),
                    ),
                    label: 'Messages',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profil',
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
