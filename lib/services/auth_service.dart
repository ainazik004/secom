import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// ------------------------------------------------------------
  /// 🔹 Register a new user and send email verification
  /// ------------------------------------------------------------
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      // Create account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Registration failed');
      }

      // Update profile
      await user.updateDisplayName(fullName);

      // Store in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName,
        'email': email,
        'phone': phoneNumber,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send verification email
      await user.sendEmailVerification();

      // Keep user logged in, redirect handled externally
      return user;

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка регистрации');
    }
  }

  /// ------------------------------------------------------------
  /// 🔹 Login with email verification enforcement
  /// ------------------------------------------------------------
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Ошибка входа');
      }

      // Always refresh user state before checking emailVerified
      await user.reload();
      final refreshedUser = _auth.currentUser!;

      if (!refreshedUser.emailVerified) {
        await _auth.signOut();
        throw Exception('Пожалуйста, подтвердите ваш email перед входом.');
      }

      return refreshedUser;

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка входа');
    }
  }

  /// ------------------------------------------------------------
  /// 🔹 Resend verification email
  /// ------------------------------------------------------------
  Future<void> sendEmailVerification(User user) async {
    await user.reload();
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// ------------------------------------------------------------
  /// 🔹 Refresh and return current user
  /// ------------------------------------------------------------
  Future<User?> refreshUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    return _auth.currentUser;
  }
  /// ------------------------------------------------------------
  /// 🔹 Update Verified status
  /// ------------------------------------------------------------
  Future<void> updateVerifiedStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'emailVerified': true,
    });
  }


  /// ------------------------------------------------------------
  /// 🔹 Sign out
  /// ------------------------------------------------------------
  Future<void> signOut() async => _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
