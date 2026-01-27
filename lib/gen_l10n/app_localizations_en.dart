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
  String get average => 'Average';

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

  @override
  String get advancedStatisticsTitle => 'Advanced statistics';

  @override
  String get overview => 'Overview';

  @override
  String get overallAccuracy => 'Overall accuracy';

  @override
  String get categoryBreakdown => 'Category breakdown';

  @override
  String get accuracyPerCategory => 'Accuracy per category';

  @override
  String get recentTestPerformance => 'Recent test performance';

  @override
  String get recentTests => 'Recent tests';

  @override
  String get accountAndSettings => 'Account & settings';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get avgScore => 'Avg score';

  @override
  String get avgTimePerQuestion => 'Avg time / question';

  @override
  String get studyTime => 'Study time';

  @override
  String get testsCompleted => 'Tests completed';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get longestStreak => 'Longest streak';

  @override
  String get lastLogin => 'Last login';

  @override
  String get lastUpdated => 'Last updated';

  @override
  String get lastTestDate => 'Last test date';

  @override
  String get appVersion => 'App version';

  @override
  String get authProvider => 'Auth provider';

  @override
  String get premium => 'Premium';

  @override
  String get emailVerified => 'Email verified';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notAvailable => 'N/A';

  @override
  String get seconds => 's';

  @override
  String get minutes => 'min';

  @override
  String get hours => 'h';

  @override
  String get days => 'days';

  @override
  String get theme => 'Theme';

  @override
  String get quiz_review => 'Review';

  @override
  String get quiz_total => 'Total';

  @override
  String quiz_question_short(int n) {
    return 'Q$n';
  }

  @override
  String get quiz_tap_to_review => 'Tap to review';

  @override
  String quiz_review_question_title(int n, int total) {
    return 'Review: $n/$total';
  }

  @override
  String get quiz_explanation => 'Explanation';

  @override
  String get quiz_ai_explain => 'Explain with AI';

  @override
  String get quiz_progress_saved => 'Progress saved';

  @override
  String get mathIntroSubtitle => 'Practice with a short test.';

  @override
  String get testAboutTitle => 'About this test';

  @override
  String get mathTestAboutBody =>
      'You will answer a set of mathematics questions. Your results will be used to calculate your score and update your progress.';

  @override
  String get testYouWillGetTitle => 'What you’ll get';

  @override
  String get testYouWillGetBullet1 => 'A final score in percent';

  @override
  String get testYouWillGetBullet2 =>
      'A review of correct and incorrect answers';

  @override
  String get testYouWillGetBullet3 => 'Updated statistics for your profile';

  @override
  String get startTest => 'Start test';

  @override
  String get createAccountSubtitle => 'Create your account to start learning.';

  @override
  String get nameHint => 'Your name';

  @override
  String get surnameHint => 'Your surname';

  @override
  String get enterSurname => 'Please enter your surname';

  @override
  String get emailHint => 'example@mail.com';

  @override
  String get enterValidEmail => 'Please enter a val9id email';

  @override
  String get phoneHint996 => '+996XXXXXXXXX';

  @override
  String get phoneFormatError => 'Phone must be in format +996#########';

  @override
  String get passwordHint => 'At least 6 characters';

  @override
  String get confirmPasswordHint => 'Repeat your password';

  @override
  String get registerHint =>
      'After registration, you will need to verify your email.';

  @override
  String get unexpectedError => 'An error occurred. Please try again.';

  @override
  String get emailVerifiedSuccess => 'Email verified.';

  @override
  String get notVerifiedYet => 'Email has not been verified yet.';

  @override
  String get verifyEmailTitle => 'Email verification';

  @override
  String get verifyEmailSubtitle =>
      'We have sent you an email with a verification link. Open it, verify your email, then return here.';

  @override
  String get iVerifiedButton => 'I have verified';

  @override
  String get resendEmailButton => 'Resend email';

  @override
  String get verifyEmailHint =>
      'If you do not see the email, check your Spam folder or wait 1–2 minutes.';

  @override
  String get jinny => 'Jinny';

  @override
  String jinny_firstPrompt(Object correct, Object picked) {
    return 'Explain this question step-by-step. My answer: $picked. Correct answer: $correct. Also explain why the other options are wrong.';
  }

  @override
  String get chooseTheme => 'Choose theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String themeCurrentValue(String value) {
    return '$value';
  }

  @override
  String get acceptTermsToContinue =>
      'Please accept Terms of Service and Privacy Policy to continue';

  @override
  String get acceptLegalPrefix => 'I agree to the';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get acceptLegalAnd => 'and';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get acceptLegalSuffix => '.';

  @override
  String get analogyIntroSubtitle =>
      'Sharpen your logical reasoning and comparison skills.';

  @override
  String get analogyTestAboutBody =>
      'This test focuses on analogies — tasks where you must identify relationships between words, concepts, or patterns. It helps develop abstract thinking, logic, and the ability to quickly recognize meaningful connections.';

  @override
  String get grammarIntroSubtitle =>
      'Practice key grammar rules and improve accuracy.';

  @override
  String get grammarTestAboutBody =>
      'This test focuses on grammar — sentence structure, agreement, and correct usage of forms. It helps you write and speak more accurately, avoid common mistakes, and strengthen language fundamentals for exams.';

  @override
  String get readingIntroSubtitle =>
      'Improve your reading comprehension and accuracy.';

  @override
  String get readingTestAboutBody =>
      'This test focuses on reading comprehension — understanding the main idea, details, and meaning of texts. It helps you answer exam-style questions faster, build vocabulary from context, and improve your ability to analyze information.';

  @override
  String get report_a_mistake => 'Report a mistake';

  @override
  String get report_hint =>
      'Describe what is wrong (wrong answer, unclear wording, typo, bad translation, etc.). We will review and fix it.';

  @override
  String get report_placeholder =>
      'Example: Option C should be correct because… / There is a typo in the question…';

  @override
  String get sending => 'Sending…';

  @override
  String get report_sent => 'Thank you! Your report has been sent.';

  @override
  String get error_prefix => 'Error';
}
