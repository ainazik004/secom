// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get home => 'Home';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get hello => 'Hello';

  @override
  String get math => 'Mathematics';

  @override
  String get analogy => 'Analogy';

  @override
  String get reading => 'Reading';

  @override
  String get grammar => 'Grammar';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get invalidPassword => 'Incorrect password';

  @override
  String get invalidEmailOrPassword => 'Incorrect email or password';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter password';

  @override
  String get passwordShort => 'Password must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm the password';

  @override
  String get passwordNotMatching => 'Passwords do not match';

  @override
  String get enterName => 'Enter name';

  @override
  String get enterPhone => 'Enter phone number';

  @override
  String get name => 'Name';

  @override
  String get surname => 'Surname';

  @override
  String get phone => 'Phone';

  @override
  String get confirmEmail => 'Email confirmation';

  @override
  String get emailSent => 'A confirmation email has been sent.';

  @override
  String get resend => 'Resend';

  @override
  String get iVerified => 'I have verified';

  @override
  String get verificationRequired => 'Please verify your email.';

  @override
  String get loginButton => 'LOGIN';

  @override
  String get registerButton => 'REGISTER';

  @override
  String get registration => 'Registration';

  @override
  String get logout => 'Log out';

  @override
  String get logoutQuestion => 'Are you sure you want to log out?';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get cancel => 'Cancel';

  @override
  String get logoutFailed => 'Logout failed';

  @override
  String get profile => 'Profile';

  @override
  String get profileInfo => 'Profile information';

  @override
  String get fullName => 'Full name';

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not verified';

  @override
  String get createdAt => 'Account created';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get changePassword => 'Change password';

  @override
  String get notifications => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get educationCenter => 'Educational Center';

  @override
  String get welcomeDescription =>
      'A leader in preparation for ORT, holder of the record for the number of gold certificates, as well as the number of applicants scoring above 200 points.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetEmailSent => 'Password reset email sent';

  @override
  String get resetFailed => 'Failed to send reset email';

  @override
  String get send => 'Send';

  @override
  String get verifyPhone => 'Verify phone';

  @override
  String get smsCode => 'SMS code';

  @override
  String get phoneVerificationSent => 'Verification code sent';

  @override
  String get phoneVerified => 'Phone verified';

  @override
  String get phoneUpdated => 'Phone updated';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get homeCategories => 'Practice Categories';

  @override
  String get invalidCode => 'Invalid code, please try again.';

  @override
  String get statistics => 'Statistics';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsSubtitle => 'Track your progress';

  @override
  String get statsCompleted => 'Completed tasks';

  @override
  String get statsAccuracy => 'Accuracy';

  @override
  String get statsTimeSpent => 'Study time';

  @override
  String get leaderboardTitle => 'Top Students';

  @override
  String get noUsers => 'No users found';

  @override
  String get trophies => 'Trophies';

  @override
  String get welcomeTitle => 'Welcome to ZHALBYRAK';

  @override
  String get welcomeSubtitle => 'Prep smart, enjoy learning, reach your goals.';

  @override
  String get welcomeToSecom => 'Welcome to ZHALBYRAK';

  @override
  String get prepSmart => 'Prep smart, enjoy learning, reach your goals.';

  @override
  String get over500questions => '500+ Questions';

  @override
  String get sharpenReasoning => 'Sharpen reasoning skills';

  @override
  String get over400passages => '400+ Passages';

  @override
  String get over2000questions => '2000+ Questions';

  @override
  String get answered => 'answered';

  @override
  String get correct => 'correct';

  @override
  String get resetEmailRequired => 'Please enter your email';

  @override
  String get invalidPhone => 'Enter a valid phone number';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get quiz_result_title => 'Result';

  @override
  String quiz_correct_out_of(Object correct, Object total) {
    return 'Correct: $correct out of $total';
  }

  @override
  String quiz_score_pct(Object score) {
    return 'Score: $score%';
  }

  @override
  String get quiz_close => 'Close';

  @override
  String get quiz_retry => 'Try again';

  @override
  String get quiz_empty_title => 'Empty';

  @override
  String get quiz_empty_subtitle => 'No questions found for this test.';

  @override
  String get quiz_back => 'Back';

  @override
  String get quiz_load_error_title => 'Loading error';

  @override
  String get quiz_retry_btn => 'Retry';

  @override
  String quiz_question_of(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get quiz_finish => 'Finish';

  @override
  String get quiz_next => 'Next';

  @override
  String get quiz_correct => 'Correct ✅ (+1 trophy)';

  @override
  String quiz_wrong_correct_answer(Object answer) {
    return 'Wrong ❌ (correct answer: $answer)';
  }

  @override
  String quiz_difficulty(Object difficulty) {
    return 'Difficulty: $difficulty';
  }

  @override
  String statsAnsweredOutOf(int answered, int total) {
    return '$answered / $total';
  }

  @override
  String get notLoggedIn => 'Not logged in';

  @override
  String get noStatisticsYet => 'No statistics yet';

  @override
  String get advancedStatistics => 'Advanced statistics';
}
