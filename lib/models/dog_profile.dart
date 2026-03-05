// Firestore collection: dogProfiles/{dogId}

import 'package:cloud_firestore/cloud_firestore.dart';

class DogProfile {
  final String id;
  final String ownerId;
  final String name;
  final String breed;
  final String color;
  final String? photoUrl;
  final String? description;
  final DateTime? birthDate;
  final String? gender;
  final double? weight;
  final int timesLogged;
  final DateTime createdAt;
  final DateTime updatedAt;

  DogProfile({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.color,
    this.photoUrl,
    this.description,
    this.birthDate,
    this.gender,
    this.weight,
    this.timesLogged = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  DogProfile copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? breed,
    String? color,
    String? photoUrl,
    String? description,
    DateTime? birthDate,
    String? gender,
    double? weight,
    int? timesLogged,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DogProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      photoUrl: photoUrl ?? this.photoUrl,
      description: description ?? this.description,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      weight: weight ?? this.weight,
      timesLogged: timesLogged ?? this.timesLogged,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  DogProfile incrementTimesLogged() {
    return copyWith(
      timesLogged: timesLogged + 1,
      updatedAt: DateTime.now(),
    );
  }

  String get ageString {
    if (birthDate == null) return 'Unknown age';
    
    final now = DateTime.now();
    final difference = now.difference(birthDate!);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    
    if (years > 0) {
      return years == 1 ? '1 year old' : '$years years old';
    } else if (months > 0) {
      return months == 1 ? '1 month old' : '$months months old';
    } else {
      return 'Puppy';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'color': color,
      'photoUrl': photoUrl,
      'description': description,
      'birthDate': birthDate?.toIso8601String(),
      'gender': gender,
      'weight': weight,
      'timesLogged': timesLogged,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory DogProfile.fromJson(Map<String, dynamic> json) {
    return DogProfile(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      breed: json['breed'] as String,
      color: json['color'] as String,
      photoUrl: json['photoUrl'] as String?,
      description: json['description'] as String?,
      birthDate: json['birthDate'] != null 
          ? DateTime.parse(json['birthDate'] as String) 
          : null,
      gender: json['gender'] as String?,
      weight: json['weight'] as double?,
      timesLogged: json['timesLogged'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Serializes to Firestore document body (excludes id — that's the doc ID).
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'name': name,
      'breed': breed,
      'color': color,
      'photoUrl': photoUrl,
      'description': description,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'weight': weight,
      'timesLogged': timesLogged,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DogProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return DogProfile(
      id: doc.id,
      ownerId: data['ownerId'] as String,
      name: data['name'] as String,
      breed: data['breed'] as String,
      color: data['color'] as String,
      photoUrl: data['photoUrl'] as String?,
      description: data['description'] as String?,
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      gender: data['gender'] as String?,
      weight: (data['weight'] as num?)?.toDouble(),
      timesLogged: data['timesLogged'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  @override
  String toString() {
    return 'DogProfile(id: $id, name: $name, breed: $breed, owner: $ownerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DogProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}