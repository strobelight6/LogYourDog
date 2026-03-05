class DogPost {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String dogName;
  final String breed;
  final String color;
  final String location;
  final int rating; // 1-5 paws
  final String? photoUrl;
  final String? taggedDogId; // Optional: reference to existing dog profile
  final DateTime createdAt;
  final List<String> likedByUserIds;
  final List<DogPostComment> comments;

  DogPost({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.dogName,
    required this.breed,
    required this.color,
    required this.location,
    required this.rating,
    this.photoUrl,
    this.taggedDogId,
    required this.createdAt,
    List<String>? likedByUserIds,
    List<DogPostComment>? comments,
  }) : likedByUserIds = likedByUserIds ?? [],
       comments = comments ?? [];

  DogPost copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfilePicture,
    String? dogName,
    String? breed,
    String? color,
    String? location,
    int? rating,
    String? photoUrl,
    String? taggedDogId,
    DateTime? createdAt,
    List<String>? likedByUserIds,
    List<DogPostComment>? comments,
  }) {
    return DogPost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfilePicture: userProfilePicture ?? this.userProfilePicture,
      dogName: dogName ?? this.dogName,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      photoUrl: photoUrl ?? this.photoUrl,
      taggedDogId: taggedDogId ?? this.taggedDogId,
      createdAt: createdAt ?? this.createdAt,
      likedByUserIds: likedByUserIds ?? this.likedByUserIds,
      comments: comments ?? this.comments,
    );
  }

  bool isLikedByUser(String userId) {
    return likedByUserIds.contains(userId);
  }

  DogPost toggleLike(String userId) {
    final newLikedByUserIds = List<String>.from(likedByUserIds);
    if (newLikedByUserIds.contains(userId)) {
      newLikedByUserIds.remove(userId);
    } else {
      newLikedByUserIds.add(userId);
    }
    return copyWith(likedByUserIds: newLikedByUserIds);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'dogName': dogName,
      'breed': breed,
      'color': color,
      'location': location,
      'rating': rating,
      'photoUrl': photoUrl,
      'taggedDogId': taggedDogId,
      'createdAt': createdAt.toIso8601String(),
      'likedByUserIds': likedByUserIds,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  factory DogPost.fromJson(Map<String, dynamic> json) {
    return DogPost(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userProfilePicture: json['userProfilePicture'] as String?,
      dogName: json['dogName'] as String,
      breed: json['breed'] as String,
      color: json['color'] as String,
      location: json['location'] as String,
      rating: json['rating'] as int,
      photoUrl: json['photoUrl'] as String?,
      taggedDogId: json['taggedDogId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likedByUserIds: List<String>.from(json['likedByUserIds'] as List),
      comments: (json['comments'] as List)
          .map((c) => DogPostComment.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DogPostComment {
  final String id;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final String content;
  final DateTime createdAt;

  DogPostComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DogPostComment.fromJson(Map<String, dynamic> json) {
    return DogPostComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userProfilePicture: json['userProfilePicture'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}