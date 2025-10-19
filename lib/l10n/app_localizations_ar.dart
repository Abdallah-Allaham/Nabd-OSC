// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نور';

  @override
  String get appName => 'Making Noor A Reality';

  @override
  String get welcomeMessage => 'مرحباً بك في تطبيق نور';

  @override
  String get alert => 'تنبيه';

  @override
  String get permissionsMessage =>
      'لاستمرار عمل التطبيق في الخلفية بكفاءة، نحتاج إلى هذه الأذونات. يرجى منحنا صلاحيات تجاهل استهلاك البطارية، والظهور فوق التطبيقات الأخرى، وإمكانية الوصول.';

  @override
  String get grantPermissions => 'منح الأذونات';

  @override
  String get ignore => 'تجاهل';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get enterPhoneNumberManually => 'أو أدخل رقم الهاتف يدوياً';

  @override
  String get verify => 'تحقق';

  @override
  String get createAccount => 'إنشاء حساب جديد';

  @override
  String get invalidPhoneNumber => 'رقم هاتف أردني غير صحيح';

  @override
  String phoneNumberEntered(Object phoneNumber) {
    return 'تم إدخال الرقم: $phoneNumber';
  }

  @override
  String get otpVerificationTitle => 'تحقق من الرمز السري';

  @override
  String get otpMessage => 'لقد أرسلنا رمز التحقق إلى رقم هاتفك.';

  @override
  String get smsPermissionMessage =>
      'الرجاء السماح بقراءة الرسائل لتفعيل الملء التلقائي.';

  @override
  String codeEntered(Object otpCode) {
    return 'تم إدخال الرمز: $otpCode';
  }

  @override
  String get pageHome => 'الرئيسية';

  @override
  String get pagePDFReader => 'القارئ';

  @override
  String get pageHistory => 'السجل';

  @override
  String get pageConnectivity => 'الاتصال';

  @override
  String get pageSettings => 'الإعدادات';

  @override
  String get pageProfile => 'الملف الشخصي';

  @override
  String pageOpened(Object pageTitle) {
    return 'أنت الآن في صفحة $pageTitle';
  }

  @override
  String get profileOpened => 'تم فتح صفحة الملف الشخصي';

  @override
  String get microphoneOn => 'المايك يعمل...';

  @override
  String get microphoneOffSessionEnded => 'تم إيقاف المايك (انتهاء الجلسة)';

  @override
  String get microphoneOffSilence => 'تم إيقاف المايك بسبب الصمت';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get enterNameManually => 'أو أدخل اسمك يدوياً';

  @override
  String get next => 'التالي';

  @override
  String get signup => 'تسجيل';

  @override
  String nameEntered(Object name) {
    return 'تم إدخال الاسم: $name';
  }

  @override
  String get phoneVerified => 'تم التحقق من رقم الهاتف بنجاح.';

  @override
  String get recordYourVoice => 'سجل بصمة صوتك';

  @override
  String get voiceEnrollmentMessage =>
      'اضغط على الزر أدناه وتحدث لمدة 7 ثوانٍ لتسجيل بصمتك الصوتية.';

  @override
  String get startRecording => 'ابدأ التسجيل';

  @override
  String get completingSignup => 'جاري إتمام عملية التسجيل...';

  @override
  String signupError(Object errorMessage) {
    return 'خطأ في التسجيل: $errorMessage';
  }

  @override
  String get loginPageSemantics =>
      'صفحة تسجيل الدخول، أدخل رقم هاتفك عن طريق الكلام أو الكتابة.';

  @override
  String get otpScreenSemantics =>
      'صفحة التحقق من الرمز السري، أدخل رمز التحقق عن طريق الكلام أو الكتابة.';

  @override
  String get home => 'الرئيسية';

  @override
  String get history => 'السجل';

  @override
  String get setting => 'الاعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get pdfreader => 'Pdf قارئ';

  @override
  String get switch_language => 'اللغة';

  @override
  String get logout => 'تسجيل خروج';

  @override
  String get connectivity => 'الاتصال';

  @override
  String get account_info => 'معلومات الحساب';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get edit => 'تعديل';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String new_value(Object field) {
    return 'أدخل $field الجديد';
  }

  @override
  String get camera => 'كاميرا';

  @override
  String get cameraOpened => 'الكاميرا مفتوحة';

  @override
  String get cameraClosed => 'الكاميرا مغلقة';

  @override
  String get cameraInitializing => 'جاري تشغيل الكاميرا...';

  @override
  String get cameraPermissionRequired => 'إذن الكاميرا مطلوب';

  @override
  String get cameraPermissionMessage =>
      'هذا التطبيق يحتاج إذن الكاميرا لالتقاط الصور.';

  @override
  String get cameraError => 'خطأ';

  @override
  String get photoCapturedSuccessfully => 'تم التقاط الصورة بنجاح!';

  @override
  String get failedToCapturePhoto => 'فشل في التقاط الصورة';

  @override
  String get failedToInitializeCamera => 'فشل في تشغيل الكاميرا';

  @override
  String get retake => 'إعادة التقاط';

  @override
  String get settings => 'الإعدادات';

  @override
  String get wifiQrTitle => 'رمز QR للواي فاي';

  @override
  String get networkName => 'اسم الشبكة';

  @override
  String get password => 'كلمة المرور';

  @override
  String get userId => 'معرف المستخدم';

  @override
  String get qrInstructions =>
      'امسح هذا الرمز بجهاز آخر للاتصال بشبكة الواي فاي';

  @override
  String get close => 'إغلاق';

  @override
  String get capturing => 'جاري التقاط';

  @override
  String get qrVisible => 'تم اكتشاف رمز QR';

  @override
  String get wifiShare => 'مشاركة الواي فاي';

  @override
  String get generateQr => 'إنشاء رمز QR';

  @override
  String get opening_wifi_settings => 'فتح إعدادات الواي فاي';

  @override
  String get code_ready => 'الكود جاهز';

  @override
  String get fallback_use_system_qr => 'استخدم رمز النظام';

  @override
  String get confirm_identity => 'تأكيد الهوية';

  @override
  String get operation_successful => 'تمت العملية بنجاح';

  @override
  String get wifi_settings_opened =>
      'تم فتح إعدادات الواي فاي. سيقوم النظام بالانتقال تلقائياً إلى الشبكة المتصلة وعرض رمز QR.';

  @override
  String get guidance_move_down_right => 'حرّك الهاتف للأسفل واليمين';

  @override
  String get guidance_move_down_left => 'حرّك الهاتف للأسفل واليسار';

  @override
  String get guidance_move_up_right => 'حرّك الهاتف للأعلى واليمين';

  @override
  String get guidance_move_up_left => 'حرّك الهاتف للأعلى واليسار';

  @override
  String get guidance_move_away => 'ابتعد قليلًا عن الورقة';

  @override
  String get guidance_perfect => 'إطار مثالي';

  @override
  String get guidance_no_document => 'لم يتم العثور على مستند';

  @override
  String get guidance_unknown => 'توجيه غير معروف';

  @override
  String get guidance_raise_phone => 'ارفع الهاتف قليلًا';

  @override
  String get guidance_away_and_raise => 'ابتعد قليلًا وارفع الهاتف قليلًا';

  @override
  String get guidance_connected => 'متصل';

  @override
  String get guidance_disconnected => 'غير متصل';
}
