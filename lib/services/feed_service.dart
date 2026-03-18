import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dog_post.dart';

class FeedService {
  static FeedService? _instance;

  FeedService._();

  static FeedService get instance {
    _instance ??= FeedService._();
    return _instance!;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('dogPosts');

  Future<List<DogPost>> getFeedPosts({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query =
          _col.orderBy('createdAt', descending: true);
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs.map((d) => DogPost.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading feed: $e');
      return [];
    }
  }

  Future<List<DogPost>> getUserPosts(String userId, {int? limit}) async {
    try {
      Query<Map<String, dynamic>> query = _col
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs.map((d) => DogPost.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading user posts: $e');
      return [];
    }
  }

  Future<DogPost> createPost(DogPost post) async {
    await _col.doc(post.id).set(post.toFirestore());
    return post;
  }

  Future<DogPost> updatePost(DogPost post) async {
    await _col.doc(post.id).update(post.toFirestore());
    return post;
  }

  Future<bool> deletePost(String postId) async {
    try {
      await _col.doc(postId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  Future<DogPost> toggleLike(String postId, String userId) async {
    final ref = _col.doc(postId);
    final doc = await ref.get();
    if (!doc.exists) throw Exception('Post not found');

    final post = DogPost.fromFirestore(doc);
    final liked = post.likedByUserIds.contains(userId);
    await ref.update({
      'likedByUserIds': liked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });

    return DogPost.fromFirestore(await ref.get());
  }
}
