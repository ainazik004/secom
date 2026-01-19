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
