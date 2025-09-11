import 'dart:typed_data';

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<bool> checkIfUserExists(String phoneNumber);
  Future<UserEntity> verifyOtpAndLogin(String otp);
  Future<void> signupUser(String uid,String phoneNumber, String name, String voiceProfileData);
  Future<bool> checkVoiceIdEnrollment();
  Future<String> uploadVoiceProfile(String uid, Uint8List voiceProfileBytes);
  Future<List<int>?> getCachedVoiceProfileData();
  Future<List<int>?> downloadUserVoiceProfile(String uid);
  Future<void> cacheVoiceProfileData(List<int> voiceProfileBytes);
  Future<UserEntity> getUserData(String uid);
  Future<bool> isUserLoggedIn();
  Future<void> logout();
}