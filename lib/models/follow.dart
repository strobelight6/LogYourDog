// Firestore collection: follows/{followerId}_{followingId}
// Document ID is composite: "{followerId}_{followingId}"

import 'package:cloud_firestore/cloud_firestore.dart';

class Follow {
  final String followerId;
  final String followingId;
  final DateTime createdAt;

  Follow({
    required this.followerId,
    required this.followingId,
    required this.createdAt,
  });

  /// The Firestore document ID for this follow relationship.
  String get docId => '${followerId}_$followingId';

  Map<String, dynamic> toFirestore() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Follow.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Follow(
      followerId: data['followerId'] as String,
      followingId: data['followingId'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      followerId: json['followerId'] as String,
      followingId: json['followingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
