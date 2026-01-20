import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  /// ------------------------------------------------------------
  /// Register AUTH user only (NO Firestore doc here)
  /// Sends verification email with optional ActionCodeSettings
  /// ------------------------------------------------------------
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber, // kept for your UI; not used here
    ActionCodeSettings? actionCodeSettings,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      await user.updateDisplayName(fullName);

      // Send verification email ONCE (with branded link if provided)
      if (!user.emailVerified) {
        if (actionCodeSettings != null) {
          await user.sendEmailVerification(actionCodeSettings);
        } else {
          await user.sendEmailVerification();
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// ------------------------------------------------------------
  /// Login: do NOT sign out if unverified (UI decides where to route)
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
      if (user == null) return null;

      await user.reload();
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? e.code);
    }
  }

  /// ------------------------------------------------------------
  /// Resend verification email for CURRENT user
  /// ------------------------------------------------------------
  Future<void> sendEmailVerification({
    ActionCodeSettings? actionCodeSettings,
    String? languageCode,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.reload();
    if (user.emailVerified) return;

    // Best-effort language
    if (languageCode != null) {
      try {
        await _auth.setLanguageCode(languageCode);
      } catch (_) {}
    }

    if (actionCodeSettings != null) {
      await user.sendEmailVerification(actionCodeSettings);
    } else {
      await user.sendEmailVerification();
    }
  }

  /// ------------------------------------------------------------
  /// Create Firestore user doc ONLY AFTER email is verified
  /// This writes the user AND all required fields only after verification.
  /// ------------------------------------------------------------
  Future<void> createUserDocIfVerified({
    required String displayName,
    required String firstName,
    required String surname,
    required String phoneNumber,
    required String languageCode, // 'ru' or 'ky'
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    await user.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) throw Exception('Not signed in');

    if (!refreshed.emailVerified) {
      throw Exception('Email not verified yet');
    }

    final docRef = _firestore.collection('users').doc(refreshed.uid);
    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (snap.exists) {
        // If doc already exists, only enforce verified flags
        tx.set(
          docRef,
          {
            'emailVerified': true,
            'isEmailVerified': true,
            'lastLoginAt': now,
          },
          SetOptions(merge: true),
        );
        return;
      }

      // Create the full initial document ONLY here (after verification)
      tx.set(docRef, {
        'uid': refreshed.uid,
        'email': refreshed.email,
        'displayName': (refreshed.displayName?.trim().isNotEmpty == true)
            ? refreshed.displayName
            : displayName,
        'firstName': firstName,
        'surname': surname,
        'phoneNumber': phoneNumber,
        'photoUrl': refreshed.photoURL ?? "",

        'authProvider': 'password',

        'emailVerified': true,
        'isEmailVerified': true,
        'phoneVerified': false,

        'createdAt': now,
        'lastLoginAt': now,

        'country': null,
        'birthYear': null,
        'educationLevel': null,
        'hasCompletedOnboarding': false,
        'hasAcceptedTerms': true,
        'referralCode': null,

        'languageCode': (languageCode == 'ky') ? 'ky' : 'ru',
        'theme': 'system',
        'notificationsEnabled': true,
        'soundEnabled': true,
        'vibrationEnabled': true,
        'fcmToken': null,

        'totalQuestionsAnswered': 0,
        'totalCorrectAnswers': 0,
        'totalTestsCompleted': 0,
        'totalStudyTimeSeconds': 0,
        'averageScore': 0.0,
        'averageTimePerQuestionSeconds': 0.0,
        'currentStreakDays': 0,
        'longestStreakDays': 0,
        'lastTestDate': null,

        'categoryStats': {
          'math': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
          'analogy': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
          'reading': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
          'grammar': {'answered': 0, 'correct': 0, 'testsCompleted': 0, 'avgScore': 0.0},
        },
        'weakCategories': [],

        // prevent crashes
        'trophies': 0,
        'leaderboardScore': 0,
        'currentRank': null,
        'bestRank': null,
        'lastLeaderboardUpdate': now,

        'defaultTestDurationMinutes': 60,
        'defaultQuestionsPerTest': 20,
        'shuffleQuestions': true,
        'shuffleAnswers': true,
        'showExplanationAfterEachQuestion': false,
        'showExplanationAtEnd': true,

        'isPremium': false,
        'subscriptionPlan': null,
        'premiumExpiresAt': null,

        'appVersion': '1.0.0',
        'platform': 'mobile',
        'lastUpdatedAt': now,
      }, SetOptions(merge: true));
    });
  }

  Future<void> signOut() async => _auth.signOut();
}
