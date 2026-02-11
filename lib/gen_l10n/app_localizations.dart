import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ky.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ky'),
    Locale('ru'),
  ];

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @math.
  ///
  /// In en, this message translates to:
  /// **'Mathematics'**
  String get math;

  /// No description provided for @analogy.
  ///
  /// In en, this message translates to:
  /// **'Analogy'**
  String get analogy;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @grammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammar;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @invalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get invalidPassword;

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get invalidEmailOrPassword;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get enterPassword;

  /// No description provided for @passwordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordShort;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm the password'**
  String get confirmPassword;

  /// No description provided for @passwordNotMatching.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordNotMatching;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter name'**
  String get enterName;

  /// No description provided for @enterPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhone;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @surname.
  ///
  /// In en, this message translates to:
  /// **'Surname'**
  String get surname;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @confirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Email confirmation'**
  String get confirmEmail;

  /// No description provided for @emailSent.
  ///
  /// In en, this message translates to:
  /// **'A confirmation email has been sent.'**
  String get emailSent;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @iVerified.
  ///
  /// In en, this message translates to:
  /// **'I have verified'**
  String get iVerified;

  /// No description provided for @verificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please verify your email.'**
  String get verificationRequired;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'REGISTER'**
  String get registerButton;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutQuestion;

  /// No description provided for @confirmation.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutFailed.
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profileInfo.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get profileInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @notVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get notVerified;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Account created'**
  String get createdAt;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @educationCenter.
  ///
  /// In en, this message translates to:
  /// **'Educational Center'**
  String get educationCenter;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'A leader in preparation for ORT, holder of the record for the number of gold certificates, as well as the number of applicants scoring above 200 points.'**
  String get welcomeDescription;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get resetEmailSent;

  /// No description provided for @resetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email'**
  String get resetFailed;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @verifyPhone.
  ///
  /// In en, this message translates to:
  /// **'Verify phone'**
  String get verifyPhone;

  /// No description provided for @smsCode.
  ///
  /// In en, this message translates to:
  /// **'SMS code'**
  String get smsCode;

  /// No description provided for @phoneVerificationSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent'**
  String get phoneVerificationSent;

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone verified'**
  String get phoneVerified;

  /// No description provided for @phoneUpdated.
  ///
  /// In en, this message translates to:
  /// **'Phone updated'**
  String get phoneUpdated;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @homeCategories.
  ///
  /// In en, this message translates to:
  /// **'Practice Categories'**
  String get homeCategories;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid code, please try again.'**
  String get invalidCode;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your progress'**
  String get statsSubtitle;

  /// No description provided for @statsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get statsCompleted;

  /// No description provided for @statsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get statsAccuracy;

  /// No description provided for @statsTimeSpent.
  ///
  /// In en, this message translates to:
  /// **'Study time'**
  String get statsTimeSpent;

  /// No description provided for @average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get average;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Students'**
  String get leaderboardTitle;

  /// No description provided for @noUsers.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsers;

  /// No description provided for @trophies.
  ///
  /// In en, this message translates to:
  /// **'Trophies'**
  String get trophies;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ZHALBYRAK'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prep smart, enjoy learning, reach your goals.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeToSecom.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ZHALBYRAK'**
  String get welcomeToSecom;

  /// No description provided for @prepSmart.
  ///
  /// In en, this message translates to:
  /// **'Prep smart, enjoy learning, reach your goals.'**
  String get prepSmart;

  /// No description provided for @over500questions.
  ///
  /// In en, this message translates to:
  /// **'500+ Questions'**
  String get over500questions;

  /// No description provided for @sharpenReasoning.
  ///
  /// In en, this message translates to:
  /// **'Sharpen reasoning skills'**
  String get sharpenReasoning;

  /// No description provided for @over400passages.
  ///
  /// In en, this message translates to:
  /// **'400+ Passages'**
  String get over400passages;

  /// No description provided for @over2000questions.
  ///
  /// In en, this message translates to:
  /// **'2000+ Questions'**
  String get over2000questions;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'answered'**
  String get answered;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'correct'**
  String get correct;

  /// No description provided for @resetEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get resetEmailRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number'**
  String get invalidPhone;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @quiz_result_title.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get quiz_result_title;

  /// No description provided for @quiz_correct_out_of.
  ///
  /// In en, this message translates to:
  /// **'Correct: {correct} out of {total}'**
  String quiz_correct_out_of(Object correct, Object total);

  /// No description provided for @quiz_score_pct.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}%'**
  String quiz_score_pct(Object score);

  /// No description provided for @quiz_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get quiz_close;

  /// No description provided for @quiz_retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get quiz_retry;

  /// No description provided for @quiz_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get quiz_empty_title;

  /// No description provided for @quiz_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'No questions found for this test.'**
  String get quiz_empty_subtitle;

  /// No description provided for @quiz_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get quiz_back;

  /// No description provided for @quiz_load_error_title.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get quiz_load_error_title;

  /// No description provided for @quiz_retry_btn.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get quiz_retry_btn;

  /// No description provided for @quiz_question_of.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String quiz_question_of(Object current, Object total);

  /// No description provided for @quiz_finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get quiz_finish;

  /// No description provided for @quiz_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quiz_next;

  /// No description provided for @quiz_correct.
  ///
  /// In en, this message translates to:
  /// **'Correct ✅ (+1 trophy)'**
  String get quiz_correct;

  /// No description provided for @quiz_wrong_correct_answer.
  ///
  /// In en, this message translates to:
  /// **'Wrong ❌ (correct answer: {answer})'**
  String quiz_wrong_correct_answer(Object answer);

  /// No description provided for @quiz_difficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty: {difficulty}'**
  String quiz_difficulty(Object difficulty);

  /// Answered questions out of total
  ///
  /// In en, this message translates to:
  /// **'{answered} / {total}'**
  String statsAnsweredOutOf(int answered, int total);

  /// No description provided for @notLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get notLoggedIn;

  /// No description provided for @noStatisticsYet.
  ///
  /// In en, this message translates to:
  /// **'No statistics yet'**
  String get noStatisticsYet;

  /// No description provided for @advancedStatistics.
  ///
  /// In en, this message translates to:
  /// **'Advanced statistics'**
  String get advancedStatistics;

  /// No description provided for @advancedStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced statistics'**
  String get advancedStatisticsTitle;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @overallAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Overall accuracy'**
  String get overallAccuracy;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category breakdown'**
  String get categoryBreakdown;

  /// No description provided for @accuracyPerCategory.
  ///
  /// In en, this message translates to:
  /// **'Accuracy per category'**
  String get accuracyPerCategory;

  /// No description provided for @recentTestPerformance.
  ///
  /// In en, this message translates to:
  /// **'Recent test performance'**
  String get recentTestPerformance;

  /// No description provided for @recentTests.
  ///
  /// In en, this message translates to:
  /// **'Recent tests'**
  String get recentTests;

  /// No description provided for @accountAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get accountAndSettings;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @avgScore.
  ///
  /// In en, this message translates to:
  /// **'Avg score'**
  String get avgScore;

  /// No description provided for @avgTimePerQuestion.
  ///
  /// In en, this message translates to:
  /// **'Avg time / question'**
  String get avgTimePerQuestion;

  /// No description provided for @studyTime.
  ///
  /// In en, this message translates to:
  /// **'Study time'**
  String get studyTime;

  /// No description provided for @testsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Tests completed'**
  String get testsCompleted;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreak;

  /// No description provided for @lastLogin.
  ///
  /// In en, this message translates to:
  /// **'Last login'**
  String get lastLogin;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get lastUpdated;

  /// No description provided for @lastTestDate.
  ///
  /// In en, this message translates to:
  /// **'Last test date'**
  String get lastTestDate;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @authProvider.
  ///
  /// In en, this message translates to:
  /// **'Auth provider'**
  String get authProvider;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailable;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get seconds;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hours;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @quiz_review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get quiz_review;

  /// No description provided for @quiz_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get quiz_total;

  /// Short label for question card in review grid
  ///
  /// In en, this message translates to:
  /// **'Q{n}'**
  String quiz_question_short(int n);

  /// No description provided for @quiz_tap_to_review.
  ///
  /// In en, this message translates to:
  /// **'Tap to review'**
  String get quiz_tap_to_review;

  /// Title for single-question review page
  ///
  /// In en, this message translates to:
  /// **'Review: {n}/{total}'**
  String quiz_review_question_title(int n, int total);

  /// No description provided for @quiz_explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get quiz_explanation;

  /// No description provided for @quiz_ai_explain.
  ///
  /// In en, this message translates to:
  /// **'Explain with AI'**
  String get quiz_ai_explain;

  /// No description provided for @quiz_progress_saved.
  ///
  /// In en, this message translates to:
  /// **'Progress saved'**
  String get quiz_progress_saved;

  /// No description provided for @mathIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice with a short test.'**
  String get mathIntroSubtitle;

  /// No description provided for @testAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About this test'**
  String get testAboutTitle;

  /// No description provided for @mathTestAboutBody.
  ///
  /// In en, this message translates to:
  /// **'You will answer a set of mathematics questions. Your results will be used to calculate your score and update your progress.'**
  String get mathTestAboutBody;

  /// No description provided for @testYouWillGetTitle.
  ///
  /// In en, this message translates to:
  /// **'What you’ll get'**
  String get testYouWillGetTitle;

  /// No description provided for @testYouWillGetBullet1.
  ///
  /// In en, this message translates to:
  /// **'A final score in percent'**
  String get testYouWillGetBullet1;

  /// No description provided for @testYouWillGetBullet2.
  ///
  /// In en, this message translates to:
  /// **'A review of correct and incorrect answers'**
  String get testYouWillGetBullet2;

  /// No description provided for @testYouWillGetBullet3.
  ///
  /// In en, this message translates to:
  /// **'Updated statistics for your profile'**
  String get testYouWillGetBullet3;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start test'**
  String get startTest;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start learning.'**
  String get createAccountSubtitle;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get nameHint;

  /// No description provided for @surnameHint.
  ///
  /// In en, this message translates to:
  /// **'Your surname'**
  String get surnameHint;

  /// No description provided for @enterSurname.
  ///
  /// In en, this message translates to:
  /// **'Please enter your surname'**
  String get enterSurname;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'example@mail.com'**
  String get emailHint;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a val9id email'**
  String get enterValidEmail;

  /// No description provided for @phoneHint996.
  ///
  /// In en, this message translates to:
  /// **'+996XXXXXXXXX'**
  String get phoneHint996;

  /// No description provided for @phoneFormatError.
  ///
  /// In en, this message translates to:
  /// **'Phone must be in format +996#########'**
  String get phoneFormatError;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHint;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get confirmPasswordHint;

  /// No description provided for @registerHint.
  ///
  /// In en, this message translates to:
  /// **'After registration, you will need to verify your email.'**
  String get registerHint;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get unexpectedError;

  /// No description provided for @emailVerifiedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Email verified.'**
  String get emailVerifiedSuccess;

  /// No description provided for @notVerifiedYet.
  ///
  /// In en, this message translates to:
  /// **'Email has not been verified yet.'**
  String get notVerifiedYet;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verification'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We have sent you an email with a verification link. Open it, verify your email, then return here.'**
  String get verifyEmailSubtitle;

  /// No description provided for @iVerifiedButton.
  ///
  /// In en, this message translates to:
  /// **'I have verified'**
  String get iVerifiedButton;

  /// No description provided for @resendEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendEmailButton;

  /// No description provided for @verifyEmailHint.
  ///
  /// In en, this message translates to:
  /// **'If you do not see the email, check your Spam folder or wait 1–2 minutes.'**
  String get verifyEmailHint;

  /// No description provided for @jinny.
  ///
  /// In en, this message translates to:
  /// **'Jinny'**
  String get jinny;

  /// No description provided for @jinny_firstPrompt.
  ///
  /// In en, this message translates to:
  /// **'Explain this question step-by-step. My answer: {picked}. Correct answer: {correct}. Also explain why the other options are wrong.'**
  String jinny_firstPrompt(Object correct, Object picked);

  /// No description provided for @chooseTheme.
  ///
  /// In en, this message translates to:
  /// **'Choose theme'**
  String get chooseTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Shows the currently selected theme mode label (System/Light/Dark).
  ///
  /// In en, this message translates to:
  /// **'{value}'**
  String themeCurrentValue(String value);

  /// No description provided for @acceptTermsToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please accept Terms of Service and Privacy Policy to continue'**
  String get acceptTermsToContinue;

  /// No description provided for @acceptLegalPrefix.
  ///
  /// In en, this message translates to:
  /// **'I agree to the'**
  String get acceptLegalPrefix;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @acceptLegalAnd.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get acceptLegalAnd;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @acceptLegalSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get acceptLegalSuffix;

  /// No description provided for @analogyIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sharpen your logical reasoning and comparison skills.'**
  String get analogyIntroSubtitle;

  /// No description provided for @analogyTestAboutBody.
  ///
  /// In en, this message translates to:
  /// **'This test focuses on analogies — tasks where you must identify relationships between words, concepts, or patterns. It helps develop abstract thinking, logic, and the ability to quickly recognize meaningful connections.'**
  String get analogyTestAboutBody;

  /// No description provided for @grammarIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice key grammar rules and improve accuracy.'**
  String get grammarIntroSubtitle;

  /// No description provided for @grammarTestAboutBody.
  ///
  /// In en, this message translates to:
  /// **'This test focuses on grammar — sentence structure, agreement, and correct usage of forms. It helps you write and speak more accurately, avoid common mistakes, and strengthen language fundamentals for exams.'**
  String get grammarTestAboutBody;

  /// No description provided for @readingIntroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Improve your reading comprehension and accuracy.'**
  String get readingIntroSubtitle;

  /// No description provided for @readingTestAboutBody.
  ///
  /// In en, this message translates to:
  /// **'This test focuses on reading comprehension — understanding the main idea, details, and meaning of texts. It helps you answer exam-style questions faster, build vocabulary from context, and improve your ability to analyze information.'**
  String get readingTestAboutBody;

  /// No description provided for @report_a_mistake.
  ///
  /// In en, this message translates to:
  /// **'Report a mistake'**
  String get report_a_mistake;

  /// No description provided for @report_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe what is wrong (wrong answer, unclear wording, typo, bad translation, etc.). We will review and fix it.'**
  String get report_hint;

  /// No description provided for @report_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Example: Option C should be correct because… / There is a typo in the question…'**
  String get report_placeholder;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get sending;

  /// No description provided for @report_sent.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your report has been sent.'**
  String get report_sent;

  /// No description provided for @error_prefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error_prefix;

  /// No description provided for @login_required.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to send a report.'**
  String get login_required;

  /// No description provided for @invalid_input.
  ///
  /// In en, this message translates to:
  /// **'Invalid input.'**
  String get invalid_input;

  /// No description provided for @daily_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Daily report limit reached (10 per day). Try again tomorrow.'**
  String get daily_limit_reached;

  /// No description provided for @ortMockTestTitle.
  ///
  /// In en, this message translates to:
  /// **'ORT mock test'**
  String get ortMockTestTitle;

  /// No description provided for @ortMockTestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Full exam simulation with timer and review'**
  String get ortMockTestSubtitle;

  /// No description provided for @submit_section.
  ///
  /// In en, this message translates to:
  /// **'Submit section'**
  String get submit_section;

  /// No description provided for @quiz_progress.
  ///
  /// In en, this message translates to:
  /// **'{answered}/{total} answered'**
  String quiz_progress(Object answered, Object total);

  /// No description provided for @sentence_completion.
  ///
  /// In en, this message translates to:
  /// **'Sentence completion'**
  String get sentence_completion;

  /// No description provided for @mock_title.
  ///
  /// In en, this message translates to:
  /// **'ORT Mock Test'**
  String get mock_title;

  /// No description provided for @mock_setup_required_title.
  ///
  /// In en, this message translates to:
  /// **'Setup required'**
  String get mock_setup_required_title;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @mock_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Full-length mock test'**
  String get mock_hero_title;

  /// No description provided for @mock_hero_desc.
  ///
  /// In en, this message translates to:
  /// **'Take a realistic ORT-style mock with the same section order. Your progress is saved automatically, so you can continue anytime.'**
  String get mock_hero_desc;

  /// No description provided for @mock_overview_title.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get mock_overview_title;

  /// No description provided for @mock_sections_title.
  ///
  /// In en, this message translates to:
  /// **'Sections'**
  String get mock_sections_title;

  /// No description provided for @mock_sections_value.
  ///
  /// In en, this message translates to:
  /// **'5 sections'**
  String get mock_sections_value;

  /// No description provided for @mock_order_title.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get mock_order_title;

  /// No description provided for @mock_order_value.
  ///
  /// In en, this message translates to:
  /// **'math → analogy → sentence completion → reading → grammar'**
  String get mock_order_value;

  /// No description provided for @mock_time_title.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get mock_time_title;

  /// No description provided for @mock_time_value.
  ///
  /// In en, this message translates to:
  /// **'Use it as a timed mock, or practice without strict timing.'**
  String get mock_time_value;

  /// No description provided for @mock_tips_title.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get mock_tips_title;

  /// No description provided for @mock_tip_1.
  ///
  /// In en, this message translates to:
  /// **'Answer consistently—guessing is allowed, but try to finish every section.'**
  String get mock_tip_1;

  /// No description provided for @mock_tip_2.
  ///
  /// In en, this message translates to:
  /// **'You can pause and continue later—your answers are saved.'**
  String get mock_tip_2;

  /// No description provided for @mock_tip_3.
  ///
  /// In en, this message translates to:
  /// **'After finishing, review mistakes and request Jinny explanations.'**
  String get mock_tip_3;

  /// No description provided for @mock_start_new.
  ///
  /// In en, this message translates to:
  /// **'Start new mock'**
  String get mock_start_new;

  /// No description provided for @mock_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue current mock'**
  String get mock_continue;

  /// No description provided for @mock_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard current mock'**
  String get mock_discard;

  /// No description provided for @mock_discard_title.
  ///
  /// In en, this message translates to:
  /// **'Discard current mock?'**
  String get mock_discard_title;

  /// No description provided for @mock_discard_desc.
  ///
  /// In en, this message translates to:
  /// **'Your current mock progress will be deleted. This action cannot be undone.'**
  String get mock_discard_desc;

  /// No description provided for @mock_no_active_progress.
  ///
  /// In en, this message translates to:
  /// **'No active attempt'**
  String get mock_no_active_progress;

  /// No description provided for @mock_progress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {answered}/{total} answered'**
  String mock_progress(int answered, int total);

  /// No description provided for @mock_progress_unknown_total.
  ///
  /// In en, this message translates to:
  /// **'Progress: {answered} answered'**
  String mock_progress_unknown_total(int answered);

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @test_paused_exit_confirm.
  ///
  /// In en, this message translates to:
  /// **'The test is paused. Do you want to exit?'**
  String get test_paused_exit_confirm;

  /// No description provided for @test_paused_title.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get test_paused_title;

  /// No description provided for @test_paused_subtitle.
  ///
  /// In en, this message translates to:
  /// **'The timer is stopped. Tap Resume to continue.'**
  String get test_paused_subtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ky', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ky':
      return AppLocalizationsKy();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
