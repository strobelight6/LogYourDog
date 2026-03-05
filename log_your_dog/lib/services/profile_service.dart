import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';
  static ProfileService? _instance;
  
  ProfileService._();
  
  static ProfileService get instance {
    _instance ??= ProfileService._();
    return _instance!;
  }

  Future<UserProfile> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);
      
      if (profileJson != null) {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileMap);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    
    return UserProfile.defaultProfile;
  }

  Future<bool> saveProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toJson());
      return await prefs.setString(_profileKey, profileJson);
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }

  Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_profileKey);
    } catch (e) {
      debugPrint('Error clearing profile: $e');
      return false;
    }
  }
}