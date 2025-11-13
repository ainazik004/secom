import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Register
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(fullName);

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'phone': phoneNumber,
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await user.sendEmailVerification();
        await user.reload();
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка регистрации');
    }
  }

  // 🔹 Login with verification enforcement
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

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        throw Exception('Пожалуйста, подтвердите ваш email перед входом.');
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Ошибка входа');
    }
  }

  // 🔹 Resend verification
  Future<void> sendEmailVerification(User user) async {
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // 🔹 Helpers
  User? get currentUser => _auth.currentUser;

  Future<void> signOut() async => _auth.signOut();
}
