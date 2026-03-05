import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dog_profile.dart';

abstract class IDogRepository {
  Future<List<DogProfile>> getDogsByOwner(String ownerId);
  Future<List<DogProfile>> getAllDogs({int? limit});
  Future<DogProfile> saveDog(DogProfile dog);
  Future<DogProfile> updateDog(DogProfile dog);
  Future<bool> deleteDog(String dogId);
  Future<DogProfile?> getDogById(String dogId);
  Future<List<DogProfile>> searchDogs(String query, {String? excludeOwnerId});
}

class LocalDogRepository implements IDogRepository {
  static const String _dogsKey = 'owned_dogs';

  @override
  Future<List<DogProfile>> getDogsByOwner(String ownerId) async {
    try {
      final allDogs = await getAllDogs();
      return allDogs.where((dog) => dog.ownerId == ownerId).toList();
    } catch (e) {
      debugPrint('Error loading dogs by owner: $e');
      return [];
    }
  }

  @override
  Future<List<DogProfile>> getAllDogs({int? limit}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dogsJson = prefs.getString(_dogsKey);
      
      if (dogsJson != null) {
        final List<dynamic> dogsList = jsonDecode(dogsJson);
        var dogs = dogsList
            .map((json) => DogProfile.fromJson(json as Map<String, dynamic>))
            .toList();
        
        // Sort by creation date (newest first)
        dogs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        
        // Apply limit if specified
        if (limit != null && dogs.length > limit) {
          dogs = dogs.take(limit).toList();
        }
        
        return dogs;
      }
    } catch (e) {
      debugPrint('Error loading all dogs: $e');
    }
    
    return [];
  }

  @override
  Future<DogProfile> saveDog(DogProfile dog) async {
    final dogs = await getAllDogs();
    dogs.insert(0, dog); // Add to beginning
    await _saveDogs(dogs);
    return dog;
  }

  @override
  Future<DogProfile> updateDog(DogProfile dog) async {
    final dogs = await getAllDogs();
    final index = dogs.indexWhere((d) => d.id == dog.id);
    
    if (index != -1) {
      dogs[index] = dog;
      await _saveDogs(dogs);
      return dog;
    }
    
    throw Exception('Dog not found');
  }

  @override
  Future<bool> deleteDog(String dogId) async {
    final dogs = await getAllDogs();
    final originalLength = dogs.length;
    dogs.removeWhere((d) => d.id == dogId);
    
    if (dogs.length < originalLength) {
      await _saveDogs(dogs);
      return true;
    }
    
    return false;
  }

  @override
  Future<DogProfile?> getDogById(String dogId) async {
    try {
      final dogs = await getAllDogs();
      return dogs.firstWhere((dog) => dog.id == dogId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<DogProfile>> searchDogs(String query, {String? excludeOwnerId}) async {
    try {
      final allDogs = await getAllDogs();
      final lowercaseQuery = query.toLowerCase();
      
      return allDogs.where((dog) {
        // Exclude own dogs if specified
        if (excludeOwnerId != null && dog.ownerId == excludeOwnerId) {
          return false;
        }
        
        // Search in name, breed, and color
        return dog.name.toLowerCase().contains(lowercaseQuery) ||
               dog.breed.toLowerCase().contains(lowercaseQuery) ||
               dog.color.toLowerCase().contains(lowercaseQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching dogs: $e');
      return [];
    }
  }

  Future<void> _saveDogs(List<DogProfile> dogs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dogsJson = jsonEncode(dogs.map((d) => d.toJson()).toList());
      await prefs.setString(_dogsKey, dogsJson);
    } catch (e) {
      debugPrint('Error saving dogs: $e');
      rethrow;
    }
  }
}

// Cloud implementation placeholder - ready for future Firebase/API integration
class CloudDogRepository implements IDogRepository {
  @override
  Future<List<DogProfile>> getDogsByOwner(String ownerId) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<List<DogProfile>> getAllDogs({int? limit}) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogProfile> saveDog(DogProfile dog) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogProfile> updateDog(DogProfile dog) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<bool> deleteDog(String dogId) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<DogProfile?> getDogById(String dogId) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }

  @override
  Future<List<DogProfile>> searchDogs(String query, {String? excludeOwnerId}) async {
    throw UnimplementedError('Cloud implementation not yet available');
  }
}

class DogService {
  static DogService? _instance;
  late final IDogRepository _repository;
  
  DogService._({required IDogRepository repository}) : _repository = repository;
  
  static DogService get instance {
    _instance ??= DogService._(repository: LocalDogRepository());
    return _instance!;
  }

  // Method to switch to cloud implementation when ready
  static void initializeWithCloud() {
    _instance = DogService._(repository: CloudDogRepository());
  }

  Future<List<DogProfile>> getMyDogs(String ownerId) async {
    return await _repository.getDogsByOwner(ownerId);
  }

  Future<List<DogProfile>> getAllDogs({int? limit}) async {
    return await _repository.getAllDogs(limit: limit);
  }

  Future<DogProfile> addDog(DogProfile dog) async {
    return await _repository.saveDog(dog);
  }

  Future<DogProfile> updateDog(DogProfile dog) async {
    return await _repository.updateDog(dog);
  }

  Future<bool> deleteDog(String dogId) async {
    return await _repository.deleteDog(dogId);
  }

  Future<DogProfile?> getDogById(String dogId) async {
    return await _repository.getDogById(dogId);
  }

  Future<List<DogProfile>> searchDogs(String query, {String? excludeOwnerId}) async {
    return await _repository.searchDogs(query, excludeOwnerId: excludeOwnerId);
  }

  Future<DogProfile> incrementTimesLogged(String dogId) async {
    final dog = await getDogById(dogId);
    if (dog != null) {
      final updatedDog = dog.incrementTimesLogged();
      return await updateDog(updatedDog);
    }
    throw Exception('Dog not found');
  }
}