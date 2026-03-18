import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class ProfileService {
  static ProfileService? _instance;

  ProfileService._();

  static ProfileService get instance {
    _instance ??= ProfileService._();
    return _instance!;
  }

  Future<UserProfile> loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return UserProfile.defaultProfile;

      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
    return UserProfile.defaultProfile;
  }

  Future<bool> saveProfile(UserProfile profile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return false;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(profile.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }
}
