import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';

import '../../../../core/services/background_service_manager.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/services/voice_id_service.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/check_if_user_exists_usecase.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/upload_voice_profile_usecase.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final VerifyOtpUsecase verifyOtpUsecase;
  final CheckAuthStatusUsecase checkAuthStatusUsecase;
  final CheckIfUserExistsUsecase checkIfUserExistsUsecase;
  final SignupUsecase signupUsecase;
  final UploadVoiceProfileUsecase uploadVoiceProfileUsecase;
  final STTService sttService;
  final VoiceIdService voiceIdService;
  final FlutterSecureStorage secureStorage;
  final AuthRepository authRepository;

  String? _verificationId;
  String? _phoneNumber;
  bool? _isLoginFlow;
  String? _userName;

  AuthCubit({
    required this.verifyOtpUsecase,
    required this.checkAuthStatusUsecase,
    required this.checkIfUserExistsUsecase,
    required this.signupUsecase,
    required this.sttService,
    required this.voiceIdService,
    required this.secureStorage,
    required this.authRepository,
    required this.uploadVoiceProfileUsecase,
  }) : super(AuthInitial()) {
    sttService.initialize(
      onResult: (text) {
        emit(AuthSpeechResult(recognizedText: text));
      },
      onCompletion: (text) {
        emit(AuthSpeechComplete(recognizedText: text));
      },
    );
  }

  Future<void> signInWithPhoneNumber(String phoneNumber) async {
    emit(AuthLoading());
    try {
      final String internationalPhoneNumber = '+962${phoneNumber.substring(1)}';
      _phoneNumber = internationalPhoneNumber;

      final userExists = await checkIfUserExistsUsecase(internationalPhoneNumber);

      if (!userExists) {
        emit(const AuthError(message: 'هذا الرقم غير مسجل. الرجاء إنشاء حساب.'));
        return;
      }

      _isLoginFlow = true;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: internationalPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && _isLoginFlow == true) {
            final userEntity = UserEntity(
              uid: currentUser.uid,
              phoneNumber: currentUser.phoneNumber ?? '',
              name: currentUser.displayName ?? 'N/A',
            );
            emit(AuthAuthenticatedForLogin(user: userEntity));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError(message: e.message ?? 'فشل التحقق من رقم الهاتف.'));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          emit(AuthOtpSentForLogin(phoneNumber: internationalPhoneNumber, verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// New function for the signup flow
  Future<void> signUpWithPhoneNumber(String phoneNumber) async {
    emit(AuthLoading());
    try {
      final String internationalPhoneNumber = '+962${phoneNumber.substring(1)}';
      _phoneNumber = internationalPhoneNumber;

      final userExists = await checkIfUserExistsUsecase(internationalPhoneNumber);
      if (userExists) {
        // رسالة الخطأ الصحيحة للتسجيل
        emit(const AuthError(message: 'هذا الرقم مسجل مسبقاً. الرجاء تسجيل الدخول.'));
        return;
      }

      _isLoginFlow = false;

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: internationalPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            final userEntity = UserEntity(
              uid: currentUser.uid,
              phoneNumber: currentUser.phoneNumber ?? '',
              name: currentUser.displayName ?? 'N/A',
            );
            emit(AuthAuthenticated(user: userEntity));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError(message: e.message ?? 'فشل التحقق من رقم الهاتف.'));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          emit(AuthOtpSentForSignup(phoneNumber: internationalPhoneNumber, verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  /// Verifies the OTP code entered by the user manually
  Future<void> verifyOtp(String otp) async {
    emit(AuthLoading());
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is not available. Please try again.');
      }
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && _isLoginFlow == true) {
        final userEntity = UserEntity(
          uid: currentUser.uid,
          phoneNumber: currentUser.phoneNumber ?? '',
          name: currentUser.displayName ?? 'N/A',
        );
        emit(AuthAuthenticatedForLogin(user: userEntity));
      } else if (currentUser != null && _isLoginFlow == false) {
        final userEntity = UserEntity(
          uid: currentUser.uid,
          phoneNumber: currentUser.phoneNumber ?? '',
          name: _userName ?? 'N/A', // استخدام _userName المحفوظ هنا
        );
        emit(AuthAuthenticated(user: userEntity));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: e.message ?? 'رمز التحقق غير صحيح.'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // دالة جديدة لحفظ الاسم
  void setUserName(String name) {
    _userName = name;
  }

  Future<void> signup(String name, String voiceProfileUrl) async {
    emit(AuthLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid.isEmpty || user.phoneNumber == null) {
        throw Exception('User is not authenticated.');
      }
      await signupUsecase(user.uid, user.phoneNumber!, name, voiceProfileUrl);
      emit(const AuthSignupSuccess(message: 'تم إنشاء حسابك بنجاح.'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> enrollVoice() async {
    emit(VoiceIdEnrollmentStarted());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.uid.isEmpty) {
        throw Exception('المستخدم غير مسجل، لا يمكن تسجيل بصمة صوت.');
      }

      final String accessKey = sl<KeyManager>().picoVoiceAccessKey;

      final voiceProfileBytes = await voiceIdService.enrollVoice(accessKey);

      if (voiceProfileBytes != null) {
        final voiceProfileUrl = await uploadVoiceProfileUsecase(
          user.uid,
          Uint8List.fromList(voiceProfileBytes),
        );

        // هنا نقوم بدمج عملية التسجيل مع الاسم
        await signup(
          _userName ?? 'N/A', // استخدام _userName المحفوظ
          voiceProfileUrl,
        );
      } else {
        emit(
          const VoiceIdEnrollmentError(
            message: 'فشل في استلام البيانات الصوتية.',
          ),
        );
      }
    } on PlatformException catch (e) {
      emit(
        VoiceIdEnrollmentError(
          message: e.message ?? 'حدث خطأ غير معروف أثناء تسجيل بصمة الصوت.',
        ),
      );
    } catch (e) {
      emit(VoiceIdEnrollmentError(message: e.toString()));
    }
  }

  @override
  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());
      final uid = await secureStorage.read(key: 'uid');

      if (uid != null && uid.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userEntity = UserEntity(
            uid: user.uid,
            phoneNumber: user.phoneNumber ?? '',
            name: 'Test User',
          );
          emit(AuthAuthenticated(user: userEntity));
        } else {
          await secureStorage.delete(key: 'uid');
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to check auth status: ${e.toString()}'));
    }
  }

  Future<void> toggleSpeechToText() async {
    emit(AuthListeningForSpeech());
    try {
      await sttService.startListening();
    } catch (e) {
      await sttService.stopListening();
      emit(AuthError(message: e.toString()));
    }
  }

  void stopSpeechToText() {
    sttService.stopListening();
  }
}
