import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Stream<User?> get authStateChanges => FirebaseAuth.instance.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserProfile> signUp(String email, String password, String displayName) async {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(displayName);

    final now = DateTime.now();
    final profile = UserProfile(
      id: user.uid,
      displayName: displayName,
      email: email,
      createdAt: now,
      updatedAt: now,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(profile.toFirestore());

    return profile;
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
