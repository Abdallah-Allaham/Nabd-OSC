import 'package:flutter/material.dart';


class AppStrings {
  static const String welcomeMessage = 'مرحبا بك في نبض';
  static const String appName = 'nabd';
  static const String invalidPhoneNumber = 'الرقم غير صالح';
  static const String userNotFoundMessage = 'هذا الرقم غير موجود في النظام. الرجاء التأكد من الرقم أو إنشاء حساب جديد.';
  static const String userAlreadyExistsMessage = 'هذا الرقم موجود بالفعل في النظام. الرجاء تسجيل الدخول.';
}

final jordanianPhoneNumberRegex = RegExp(r'^07(7|8|9)\d{7}$');
