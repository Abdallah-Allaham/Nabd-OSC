import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Nabd'**
  String get appTitle;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nabd'**
  String get appName;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Nabd app'**
  String get welcomeMessage;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @permissionsMessage.
  ///
  /// In en, this message translates to:
  /// **'To continue working efficiently in the background, we need these permissions. Please grant us permissions to ignore battery optimizations, appear on top of other apps, and accessibility.'**
  String get permissionsMessage;

  /// No description provided for @grantPermissions.
  ///
  /// In en, this message translates to:
  /// **'Grant Permissions'**
  String get grantPermissions;

  /// No description provided for @ignore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get ignore;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @enterPhoneNumberManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter your phone number manually'**
  String get enterPhoneNumberManually;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createAccount;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid Jordanian phone number'**
  String get invalidPhoneNumber;

  /// No description provided for @phoneNumberEntered.
  ///
  /// In en, this message translates to:
  /// **'The number has been entered: {phoneNumber}'**
  String phoneNumberEntered(Object phoneNumber);

  /// No description provided for @otpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerificationTitle;

  /// No description provided for @otpMessage.
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification code to your phone number.'**
  String get otpMessage;

  /// No description provided for @smsPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please allow us to read messages to enable auto-fill.'**
  String get smsPermissionMessage;

  /// No description provided for @codeEntered.
  ///
  /// In en, this message translates to:
  /// **'The code has been entered: {otpCode}'**
  String codeEntered(Object otpCode);

  /// No description provided for @pageHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pageHome;

  /// No description provided for @pagePDFReader.
  ///
  /// In en, this message translates to:
  /// **'PDF Reader'**
  String get pagePDFReader;

  /// No description provided for @pageHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get pageHistory;

  /// No description provided for @pageConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get pageConnectivity;

  /// No description provided for @pageSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pageSettings;

  /// No description provided for @pageProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get pageProfile;

  /// No description provided for @pageOpened.
  ///
  /// In en, this message translates to:
  /// **'You are now on the {pageTitle} page'**
  String pageOpened(Object pageTitle);

  /// No description provided for @profileOpened.
  ///
  /// In en, this message translates to:
  /// **'Profile page opened'**
  String get profileOpened;

  /// No description provided for @microphoneOn.
  ///
  /// In en, this message translates to:
  /// **'Microphone is on...'**
  String get microphoneOn;

  /// No description provided for @microphoneOffSessionEnded.
  ///
  /// In en, this message translates to:
  /// **'Microphone is off (session ended)'**
  String get microphoneOffSessionEnded;

  /// No description provided for @microphoneOffSilence.
  ///
  /// In en, this message translates to:
  /// **'Microphone is off due to silence'**
  String get microphoneOffSilence;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterNameManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter your name manually'**
  String get enterNameManually;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @nameEntered.
  ///
  /// In en, this message translates to:
  /// **'Name entered: {name}'**
  String nameEntered(Object name);

  /// No description provided for @phoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified successfully'**
  String get phoneVerified;

  /// No description provided for @recordYourVoice.
  ///
  /// In en, this message translates to:
  /// **'Record your voiceprint'**
  String get recordYourVoice;

  /// No description provided for @voiceEnrollmentMessage.
  ///
  /// In en, this message translates to:
  /// **'Press the button below and speak for 7 seconds to record your voiceprint.'**
  String get voiceEnrollmentMessage;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording'**
  String get startRecording;

  /// No description provided for @completingSignup.
  ///
  /// In en, this message translates to:
  /// **'Completing the registration process...'**
  String get completingSignup;

  /// No description provided for @signupError.
  ///
  /// In en, this message translates to:
  /// **'Registration error: {errorMessage}'**
  String signupError(Object errorMessage);

  /// No description provided for @loginPageSemantics.
  ///
  /// In en, this message translates to:
  /// **'Login page, enter your phone number by speaking or typing.'**
  String get loginPageSemantics;

  /// No description provided for @otpScreenSemantics.
  ///
  /// In en, this message translates to:
  /// **'OTP verification screen, enter the verification code by speaking or typing.'**
  String get otpScreenSemantics;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @setting.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get setting;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @pdfreader.
  ///
  /// In en, this message translates to:
  /// **'PDF Reader'**
  String get pdfreader;

  /// No description provided for @switch_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get switch_language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @connectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get connectivity;

  /// No description provided for @account_info.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get account_info;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Message asking user to enter new value with placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter new {field}'**
  String new_value(Object field);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
