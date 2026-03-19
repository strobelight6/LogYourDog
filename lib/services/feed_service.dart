import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/dog_post.dart';
import 'follow_service.dart';
import 'profile_service.dart';

class FeedService {
  static FeedService? _instance;

  FeedService._();

  static FeedService get instance {
    _instance ??= FeedService._();
    return _instance!;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('dogPosts');

  Future<List<DogPost>> getFeedPosts({int? limit, String? currentUserId}) async {
    try {
      final uid = currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return [];

      final followingIds = await FollowService.instance.getFollowing(uid);
      if (followingIds.isEmpty) return [];

      // Firestore whereIn supports up to 30 values; batch if needed
      final batches = <List<String>>[];
      for (var i = 0; i < followingIds.length; i += 30) {
        batches.add(followingIds.sublist(
          i,
          i + 30 > followingIds.length ? followingIds.length : i + 30,
        ));
      }

      final results = await Future.wait(batches.map((batch) {
        Query<Map<String, dynamic>> query = _col
            .where('userId', whereIn: batch)
            .orderBy('createdAt', descending: true);
        if (limit != null) query = query.limit(limit);
        return query.get();
      }));

      final posts = results
          .expand((snap) => snap.docs.map((d) => DogPost.fromFirestore(d)))
          .toList();

      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (limit != null && posts.length > limit) {
        return posts.sublist(0, limit);
      }
      return posts;
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

  Stream<List<DogPost>> watchFeedPosts({String? currentUserId}) async* {
    final uid = currentUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield [];
      return;
    }

    final followingIds = await FollowService.instance.getFollowing(uid);
    if (followingIds.isEmpty) {
      yield [];
      return;
    }

    final batches = <List<String>>[];
    for (var i = 0; i < followingIds.length; i += 30) {
      batches.add(followingIds.sublist(i, (i + 30).clamp(0, followingIds.length)));
    }

    if (batches.length == 1) {
      yield* _col
          .where('userId', whereIn: batches.first)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map((d) => DogPost.fromFirestore(d)).toList());
    } else {
      final controller = StreamController<List<DogPost>>();
      final latestResults = List<List<DogPost>>.filled(batches.length, []);
      final subs = <StreamSubscription>[];
      for (var i = 0; i < batches.length; i++) {
        final idx = i;
        subs.add(_col
            .where('userId', whereIn: batches[idx])
            .orderBy('createdAt', descending: true)
            .snapshots()
            .listen((snap) {
          latestResults[idx] = snap.docs.map((d) => DogPost.fromFirestore(d)).toList();
          final merged = latestResults.expand((l) => l).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          controller.add(merged);
        }));
      }
      controller.onCancel = () {
        for (final s in subs) {
          s.cancel();
        }
      };
      yield* controller.stream;
    }
  }

  Stream<List<DogPostComment>> watchComments(String postId) {
    return _col
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => DogPostComment.fromFirestore(d)).toList());
  }

  Future<void> addComment(String postId, String content) async {
    final user = FirebaseAuth.instance.currentUser!;
    final profile = await ProfileService.instance.loadProfile();
    final ref = _col.doc(postId).collection('comments').doc();
    final comment = DogPostComment(
      id: ref.id,
      userId: user.uid,
      userName: profile.displayName,
      userProfilePicture: profile.profilePictureUrl,
      content: content,
      createdAt: DateTime.now(),
    );
    await ref.set(comment.toFirestore());
    await _col.doc(postId).update({'commentCount': FieldValue.increment(1)});
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
