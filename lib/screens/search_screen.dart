import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/follow_service.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _results = [];
  bool _isSearching = false;
  final Map<String, bool> _followingMap = {};
  final Map<String, int> _followerCountMap = {};
  late final String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final lowerQuery = query.toLowerCase();
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: lowerQuery)
          .where('displayNameLower', isLessThan: '$lowerQuery\uf8ff')
          .limit(20)
          .get();

      final users = snap.docs
          .map((d) => UserProfile.fromFirestore(d))
          .where((u) => u.id != _currentUserId)
          .toList();

      // Fetch follow status and follower counts for all results
      final followChecks = await Future.wait(
        users.map((u) => FollowService.instance.isFollowing(u.id)),
      );
      final followerLists = await Future.wait(
        users.map((u) => FollowService.instance.getFollowers(u.id)),
      );
      final followMap = <String, bool>{};
      final countMap = <String, int>{};
      for (var i = 0; i < users.length; i++) {
        followMap[users[i].id] = followChecks[i];
        countMap[users[i].id] = followerLists[i].length;
      }

      setState(() {
        _results = users;
        _followingMap.addAll(followMap);
        _followerCountMap.addAll(countMap);
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _toggleFollow(UserProfile user) async {
    final isFollowing = _followingMap[user.id] ?? false;
    final prevCount = _followerCountMap[user.id] ?? 0;
    setState(() {
      _followingMap[user.id] = !isFollowing;
      _followerCountMap[user.id] = prevCount + (isFollowing ? -1 : 1);
    });
    try {
      if (isFollowing) {
        await FollowService.instance.unfollowUser(user.id);
      } else {
        await FollowService.instance.followUser(user.id);
      }
    } catch (e) {
      setState(() {
        _followingMap[user.id] = isFollowing;
        _followerCountMap[user.id] = prevCount;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.brown.shade50,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users by name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
              onChanged: _search,
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final user = _results[index];
                          return _buildUserTile(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Search for users',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Text(
        'No users found',
        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
      ),
    );
  }

  String _buildSubtitle(UserProfile user) {
    final count = _followerCountMap[user.id] ?? 0;
    final countStr = '$count ${count == 1 ? 'follower' : 'followers'}';
    if (user.location != null) return '${user.location!} · $countStr';
    return countStr;
  }

  Widget _buildUserTile(UserProfile user) {
    final isFollowing = _followingMap[user.id] ?? false;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.brown.shade200,
        backgroundImage: user.profilePictureUrl != null &&
                !user.profilePictureUrl!.startsWith('/')
            ? NetworkImage(user.profilePictureUrl!)
            : null,
        child: user.profilePictureUrl == null
            ? Icon(Icons.person, color: Colors.brown.shade600)
            : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(_buildSubtitle(user)),
      trailing: OutlinedButton(
        onPressed: () => _toggleFollow(user),
        style: OutlinedButton.styleFrom(
          foregroundColor: isFollowing ? Colors.grey : Colors.brown,
          side: BorderSide(
            color: isFollowing ? Colors.grey : Colors.brown,
          ),
        ),
        child: Text(isFollowing ? 'Unfollow' : 'Follow'),
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: user.id),
          ),
        );
      },
    );
  }
}
