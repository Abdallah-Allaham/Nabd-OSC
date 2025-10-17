import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:navia/core/constants/app_constants.dart';
import 'package:navia/core/utils/secure_storage_helper.dart';

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
  final SecureStorageHelper secureStorageHelper;
  final AuthRepository authRepository;

  String? _verificationId;
  bool? _isLoginFlow;
  String? _userName;
  bool _sttInitialized = false;

  AuthCubit({
    required this.verifyOtpUsecase,
    required this.checkAuthStatusUsecase,
    required this.checkIfUserExistsUsecase,
    required this.signupUsecase,
    required this.sttService,
    required this.voiceIdService,
    required this.secureStorageHelper,
    required this.authRepository,
    required this.uploadVoiceProfileUsecase,
  }) : super(AuthInitial());

  void updateSpeechResult(String recognizedText) {
    emit(AuthSpeechResult(recognizedText: recognizedText));
  }

  Future<void> _ensureSttInitialized() async {
    if (_sttInitialized) return;
    await sttService.initialize(
      onResult: (String text) {
        emit(AuthSpeechResult(recognizedText: text));
      },
      onCompletion: (String text) {
        emit(AuthSpeechComplete(recognizedText: text));
        emit(AuthStoppedListeningForSpeech());
      },
    );
    _sttInitialized = true;
  }

  Future<void> signInWithPhoneNumber(String phoneNumber) async {
    emit(AuthLoading());
    try {
      final String internationalPhoneNumber = '+962${phoneNumber.substring(1)}';

      final userExists = await checkIfUserExistsUsecase(
        internationalPhoneNumber,
      );

      if (!userExists) {
        emit(
          const AuthError(message: 'هذا الرقم غير مسجل. الرجاء إنشاء حساب.'),
        );
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
          emit(
            AuthOtpSentForLogin(
              phoneNumber: internationalPhoneNumber,
              verificationId: verificationId,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signUpWithPhoneNumber(String phoneNumber) async {
    emit(AuthLoading());
    try {
      final String internationalPhoneNumber = '+962${phoneNumber.substring(1)}';

      final userExists = await checkIfUserExistsUsecase(
        internationalPhoneNumber,
      );
      if (userExists) {
        emit(
          const AuthError(
            message: 'هذا الرقم مسجل مسبقاً. الرجاء تسجيل الدخول.',
          ),
        );
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
          emit(
            AuthOtpSentForSignup(
              phoneNumber: internationalPhoneNumber,
              verificationId: verificationId,
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

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
        // Get user data from Firestore to get the actual name
        final userEntity = await authRepository.getUserData(currentUser.uid);
        
        // Save user data to secure storage
        await secureStorageHelper.savePrefString(
          key: AppConstants.uidKey,
          value: currentUser.uid,
        );
        await secureStorageHelper.savePrefString(
          key: AppConstants.nameKey,
          value: userEntity.name,
        );
        await secureStorageHelper.savePrefString(
          key: AppConstants.phoneKey,
          value: currentUser.phoneNumber ?? '',
        );
        
        // Download and cache voice profile for wake word and voice ID service
        await _downloadAndCacheVoiceProfile(currentUser.uid);
        
        emit(AuthAuthenticatedForLogin(user: userEntity));
      } else if (currentUser != null && _isLoginFlow == false) {
        await secureStorageHelper.savePrefString(
          key: AppConstants.uidKey,
          value: currentUser.uid,
        );
        await secureStorageHelper.savePrefString(
          key: AppConstants.nameKey,
          value: _userName ?? 'N/A',
        );
        await secureStorageHelper.savePrefString(
          key: AppConstants.phoneKey,
          value: currentUser.phoneNumber ?? '',
        );
        final userEntity = UserEntity(
          uid: currentUser.uid,
          phoneNumber: currentUser.phoneNumber ?? '',
          name: _userName ?? 'N/A',
        );
        emit(AuthAuthenticated(user: userEntity));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: e.message ?? 'رمز التحقق غير صحيح.'));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

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

        await signup(_userName ?? 'N/A', voiceProfileUrl);
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

  Future<void> checkAuthStatus() async {
    try {
      emit(AuthLoading());
      final uid = await secureStorageHelper.getPrefString(
        key: AppConstants.uidKey,
        defaultValue: '',
      );

      if (uid.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userEntity = UserEntity(
            uid: user.uid,
            phoneNumber: user.phoneNumber ?? '',
            name: 'Test User',
          );
          emit(AuthAuthenticated(user: userEntity));
        } else {
          await secureStorageHelper.remove(key: AppConstants.uidKey);
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
    try {
      await _ensureSttInitialized();
      emit(AuthListeningForSpeech());
      await sttService.startListening();
    } catch (e) {
      await sttService.stopListening();
      emit(AuthError(message: e.toString()));
    }
  }

  void stopSpeechToText() {
    sttService.stopListening();
    emit(AuthStoppedListeningForSpeech());
  }

  Future<void> logout() async {
    try {
      emit(AuthLoading());
      await authRepository.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // Download and cache voice profile for wake word and voice ID service
  Future<void> _downloadAndCacheVoiceProfile(String uid) async {
    try {
      final voiceProfileBytes = await authRepository.getCachedVoiceProfileData();
      if (voiceProfileBytes != null && voiceProfileBytes.isNotEmpty) {
        // Save to native Java code for background service access
        await _saveVoiceProfileToNative(voiceProfileBytes);
        print('Voice profile loaded from cache and saved to native for user: $uid');
      } else {
        // Try to download from Firebase if not in cache
        try {
          final voiceProfileBytes = await authRepository.downloadUserVoiceProfile(uid);
          if (voiceProfileBytes != null && voiceProfileBytes.isNotEmpty) {
            await authRepository.cacheVoiceProfileData(voiceProfileBytes);
            await _saveVoiceProfileToNative(voiceProfileBytes);
            print('Voice profile downloaded and cached for user: $uid');
          } else {
            print('Voice profile not found for user: $uid');
          }
        } catch (e) {
          print('Voice profile download failed for user: $uid - $e');
        }
      }
    } catch (e) {
      print('Voice profile cache access failed for user: $uid - $e');
    }
  }

  // Save voice profile to native Java code for background service access
  Future<void> _saveVoiceProfileToNative(List<int> voiceProfileBytes) async {
    try {
      const platform = MethodChannel('nabd/voiceid');
      await platform.invokeMethod('saveVoiceProfile', {
        'voiceProfileBytes': voiceProfileBytes,
      });
    } catch (e) {
      print('Failed to save voice profile to native: $e');
    }
  }
}
