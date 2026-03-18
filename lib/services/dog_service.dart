import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/dog_profile.dart';

class DogService {
  static DogService? _instance;

  DogService._();

  static DogService get instance {
    _instance ??= DogService._();
    return _instance!;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('dogProfiles');

  Future<List<DogProfile>> getMyDogs(String ownerId) async {
    try {
      final snap = await _col
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) => DogProfile.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading dogs: $e');
      return [];
    }
  }

  Future<List<DogProfile>> getAllDogs({int? limit}) async {
    try {
      Query<Map<String, dynamic>> query =
          _col.orderBy('createdAt', descending: true);
      if (limit != null) query = query.limit(limit);
      final snap = await query.get();
      return snap.docs.map((d) => DogProfile.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('Error loading all dogs: $e');
      return [];
    }
  }

  Future<DogProfile> addDog(DogProfile dog) async {
    await _col.doc(dog.id).set(dog.toFirestore());
    return dog;
  }

  Future<DogProfile> updateDog(DogProfile dog) async {
    await _col.doc(dog.id).update(dog.toFirestore());
    return dog;
  }

  Future<bool> deleteDog(String dogId) async {
    try {
      await _col.doc(dogId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting dog: $e');
      return false;
    }
  }

  Future<DogProfile?> getDogById(String dogId) async {
    try {
      final doc = await _col.doc(dogId).get();
      if (doc.exists) return DogProfile.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error loading dog: $e');
    }
    return null;
  }

  Future<List<DogProfile>> searchDogs(String query,
      {String? excludeOwnerId}) async {
    try {
      final all = await getAllDogs();
      final lower = query.toLowerCase();
      return all.where((dog) {
        if (excludeOwnerId != null && dog.ownerId == excludeOwnerId) {
          return false;
        }
        return dog.name.toLowerCase().contains(lower) ||
            dog.breed.toLowerCase().contains(lower) ||
            dog.color.toLowerCase().contains(lower);
      }).toList();
    } catch (e) {
      debugPrint('Error searching dogs: $e');
      return [];
    }
  }

  Future<DogProfile> incrementTimesLogged(String dogId) async {
    final dog = await getDogById(dogId);
    if (dog != null) {
      return await updateDog(dog.incrementTimesLogged());
    }
    throw Exception('Dog not found');
  }
}
