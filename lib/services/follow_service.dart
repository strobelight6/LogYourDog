import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/follow.dart';

class FollowService {
  static FollowService? _instance;

  FollowService._();

  static FollowService get instance {
    _instance ??= FollowService._();
    return _instance!;
  }

  CollectionReference get _col =>
      FirebaseFirestore.instance.collection('follows');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> followUser(String targetUserId) async {
    try {
      final follow = Follow(
        followerId: _uid,
        followingId: targetUserId,
        createdAt: DateTime.now(),
      );
      await _col.doc(follow.docId).set(follow.toFirestore());
    } catch (e) {
      debugPrint('Error following user: $e');
      rethrow;
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    try {
      await _col.doc('${_uid}_$targetUserId').delete();
    } catch (e) {
      debugPrint('Error unfollowing user: $e');
      rethrow;
    }
  }

  Future<bool> isFollowing(String targetUserId) async {
    try {
      final doc = await _col.doc('${_uid}_$targetUserId').get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  Future<List<String>> getFollowing(String userId) async {
    try {
      final snap = await _col
          .where('followerId', isEqualTo: userId)
          .get();
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return data['followingId'] as String;
      }).toList();
    } catch (e) {
      debugPrint('Error getting following list: $e');
      return [];
    }
  }

  Future<List<String>> getFollowers(String userId) async {
    try {
      final snap = await _col
          .where('followingId', isEqualTo: userId)
          .get();
      return snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return data['followerId'] as String;
      }).toList();
    } catch (e) {
      debugPrint('Error getting followers list: $e');
      return [];
    }
  }
}
