// Firestore collection: notifications/{notificationId}

import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newFollower,
  postLiked,
  milestoneReached,
}

class AppNotification {
  final String id;
  final String recipientId;
  final NotificationType type;
  final String? actorId;
  final String? actorName;
  final String? postId;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    this.actorId,
    this.actorName,
    this.postId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? recipientId,
    NotificationType? type,
    String? actorId,
    String? actorName,
    String? postId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      type: type ?? this.type,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      postId: postId ?? this.postId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'type': type.name,
      'actorId': actorId,
      'actorName': actorName,
      'postId': postId,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppNotification.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return AppNotification(
      id: doc.id,
      recipientId: data['recipientId'] as String,
      type: NotificationType.values.byName(data['type'] as String),
      actorId: data['actorId'] as String?,
      actorName: data['actorName'] as String?,
      postId: data['postId'] as String?,
      message: data['message'] as String,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipientId': recipientId,
      'type': type.name,
      'actorId': actorId,
      'actorName': actorName,
      'postId': postId,
      'message': message,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      recipientId: json['recipientId'] as String,
      type: NotificationType.values.byName(json['type'] as String),
      actorId: json['actorId'] as String?,
      actorName: json['actorName'] as String?,
      postId: json['postId'] as String?,
      message: json['message'] as String,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
