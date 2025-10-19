// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Noor';

  @override
  String get appName => 'Making Noor A Reality';

  @override
  String get welcomeMessage => 'Welcome to Noor app';

  @override
  String get alert => 'Alert';

  @override
  String get permissionsMessage =>
      'To continue working efficiently in the background, we need these permissions. Please grant us permissions to ignore battery optimizations, appear on top of other apps, and accessibility.';

  @override
  String get grantPermissions => 'Grant Permissions';

  @override
  String get ignore => 'Ignore';

  @override
  String get loginTitle => 'Login';

  @override
  String get enterPhoneNumberManually => 'Or enter your phone number manually';

  @override
  String get verify => 'Verify';

  @override
  String get createAccount => 'Create New Account';

  @override
  String get invalidPhoneNumber => 'Invalid Jordanian phone number';

  @override
  String phoneNumberEntered(Object phoneNumber) {
    return 'The number has been entered: $phoneNumber';
  }

  @override
  String get otpVerificationTitle => 'OTP Verification';

  @override
  String get otpMessage =>
      'We have sent a verification code to your phone number.';

  @override
  String get smsPermissionMessage =>
      'Please allow us to read messages to enable auto-fill.';

  @override
  String codeEntered(Object otpCode) {
    return 'The code has been entered: $otpCode';
  }

  @override
  String get pageHome => 'Home';

  @override
  String get pagePDFReader => 'PDF Reader';

  @override
  String get pageHistory => 'History';

  @override
  String get pageConnectivity => 'Connectivity';

  @override
  String get pageSettings => 'Settings';

  @override
  String get pageProfile => 'Profile';

  @override
  String pageOpened(Object pageTitle) {
    return 'You are now on the $pageTitle page';
  }

  @override
  String get profileOpened => 'Profile page opened';

  @override
  String get microphoneOn => 'Microphone is on...';

  @override
  String get microphoneOffSessionEnded => 'Microphone is off (session ended)';

  @override
  String get microphoneOffSilence => 'Microphone is off due to silence';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get enterNameManually => 'Or enter your name manually';

  @override
  String get next => 'Next';

  @override
  String get signup => 'Sign Up';

  @override
  String nameEntered(Object name) {
    return 'Name entered: $name';
  }

  @override
  String get phoneVerified => 'Phone number verified successfully';

  @override
  String get recordYourVoice => 'Record your voiceprint';

  @override
  String get voiceEnrollmentMessage =>
      'Press the button below and speak for 7 seconds to record your voiceprint.';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get completingSignup => 'Completing the registration process...';

  @override
  String signupError(Object errorMessage) {
    return 'Registration error: $errorMessage';
  }

  @override
  String get loginPageSemantics =>
      'Login page, enter your phone number by speaking or typing.';

  @override
  String get otpScreenSemantics =>
      'OTP verification screen, enter the verification code by speaking or typing.';

  @override
  String get home => 'Home';

  @override
  String get history => 'History';

  @override
  String get setting => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get pdfreader => 'PDF Reader';

  @override
  String get switch_language => 'Language';

  @override
  String get logout => 'Logout';

  @override
  String get connectivity => 'Connectivity';

  @override
  String get account_info => 'Account Info';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String new_value(Object field) {
    return 'Enter new $field';
  }

  @override
  String get camera => 'Camera';

  @override
  String get cameraOpened => 'Camera is open';

  @override
  String get cameraClosed => 'Camera is closed';

  @override
  String get cameraInitializing => 'Initializing Camera...';

  @override
  String get cameraPermissionRequired => 'Camera Permission Required';

  @override
  String get cameraPermissionMessage =>
      'This app needs camera permission to take photos.';

  @override
  String get cameraError => 'Error';

  @override
  String get photoCapturedSuccessfully => 'Photo captured successfully!';

  @override
  String get failedToCapturePhoto => 'Failed to capture photo';

  @override
  String get failedToInitializeCamera => 'Failed to initialize camera';

  @override
  String get retake => 'Retake';

  @override
  String get settings => 'Settings';

  @override
  String get wifiQrTitle => 'WiFi QR Code';

  @override
  String get networkName => 'Network Name';

  @override
  String get password => 'Password';

  @override
  String get userId => 'User ID';

  @override
  String get qrInstructions =>
      'Scan this QR code with another device to connect to the WiFi network';

  @override
  String get close => 'Close';

  @override
  String get capturing => 'Capturing';

  @override
  String get qrVisible => 'QR code detected';

  @override
  String get wifiShare => 'Share WiFi';

  @override
  String get generateQr => 'Generate QR Code';

  @override
  String get opening_wifi_settings => 'Opening Wi-Fi settings';

  @override
  String get code_ready => 'Code ready';

  @override
  String get fallback_use_system_qr => 'Use system QR';

  @override
  String get confirm_identity => 'Confirm identity';

  @override
  String get operation_successful => 'Operation Successful';

  @override
  String get wifi_settings_opened =>
      'Wi-Fi settings have been opened. The system will automatically navigate to your connected network and show the QR code.';

  @override
  String get guidance_move_down_right => 'Move phone down-right';

  @override
  String get guidance_move_down_left => 'Move phone down-left';

  @override
  String get guidance_move_up_right => 'Move phone up-right';

  @override
  String get guidance_move_up_left => 'Move phone up-left';

  @override
  String get guidance_move_away => 'Move slightly away from the paper';

  @override
  String get guidance_perfect => 'Perfect framing';

  @override
  String get guidance_no_document => 'No document detected';

  @override
  String get guidance_unknown => 'Unknown guidance';

  @override
  String get guidance_raise_phone => 'Raise the phone slightly';

  @override
  String get guidance_away_and_raise =>
      'Move slightly away and raise the phone slightly';

  @override
  String get guidance_connected => 'Connected';

  @override
  String get guidance_disconnected => 'Disconnected';
}
