// Firestore collection: users/{userId}
// Document ID = Firebase Auth uid

import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? profilePictureUrl;
  final String? location;
  final String? bio;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.profilePictureUrl,
    this.location,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? profilePictureUrl,
    String? location,
    String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'location': location,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      location: json['location'] as String?,
      bio: json['bio'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serializes to Firestore document body (excludes id — that's the doc ID).
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'location': location,
      'bio': bio,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserProfile(
      id: doc.id,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      profilePictureUrl: data['profilePictureUrl'] as String?,
      location: data['location'] as String?,
      bio: data['bio'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  static UserProfile get defaultProfile => UserProfile(
    id: 'default',
    displayName: 'Dog Lover',
    email: 'user@example.com',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}