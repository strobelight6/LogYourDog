import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/dog_post.dart';
import '../services/feed_service.dart';
import '../widgets/dog_post_card.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  late final String _currentUserId;
  late final Stream<List<DogPost>> _feedStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _feedStream = FeedService.instance.watchFeedPosts(currentUserId: _currentUserId);
  }

  Future<void> _handleLike(String postId) async {
    try {
      await FeedService.instance.toggleLike(postId, _currentUserId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating like: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: Colors.brown.shade50,
      ),
      body: StreamBuilder<List<DogPost>>(
        stream: _feedStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading feed: ${snapshot.error}'));
          }
          final posts = snapshot.data;
          if (posts == null || posts.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return DogPostCard(
                key: ValueKey(post.id),
                post: post,
                currentUserId: _currentUserId,
                onLike: () => _handleLike(post.id),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Follow friends to see their dog posts here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
