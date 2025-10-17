import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<bool> checkIfUserExists(String phoneNumber) async {
    return await remoteDataSource.checkIfUserExists(phoneNumber);
  }

  @override
  Future<UserEntity> verifyOtpAndLogin(String otp) async {
    try {
      final userModel = await remoteDataSource.verifyOtpAndLogin(otp);
      await localDataSource.cacheUserLoginStatus(true, uid: userModel.uid);
      
      // Download and cache voice profile for wake word and voice ID service
      try {
        final voiceProfileBytes = await remoteDataSource.downloadUserVoiceProfile(userModel.uid);
        if (voiceProfileBytes != null && voiceProfileBytes.isNotEmpty) {
          await localDataSource.cacheVoiceProfileData(voiceProfileBytes);
          // Also save to native Java code for background service access
          await _saveVoiceProfileToNative(voiceProfileBytes);
          print('Voice profile cached and saved to native for user: ${userModel.uid}');
        } else {
          print('Voice profile not found for user: ${userModel.uid}');
        }
      } catch (e) {
        // Voice profile not found or download failed - user might not have enrolled yet
        print('Voice profile download failed for user: ${userModel.uid} - $e');
      }
      
      return userModel;
    } on ServerException {
      throw const ServerException('Failed to verify OTP or login.');
    }
  }

  @override
  Future<void> signupUser(
      String uid,
      String phoneNumber,
      String name,
      String voiceProfileData,
      ) async {
    try {
      await remoteDataSource.saveUserProfile(
        uid,
        phoneNumber,
        name,
        voiceProfileData,
      );
    } on ServerException {
      throw const ServerException('Failed to signup user.');
    }
  }

  @override
  Future<bool> checkVoiceIdEnrollment() async {
    final localProfile = await localDataSource.getVoiceProfile();
    if (localProfile != null) {
      return true;
    }
    return false;
  }

  @override
  Future<String> uploadVoiceProfile(String uid, Uint8List voiceProfileBytes) async {
    try {
      return await remoteDataSource.storeUserVoiceProfile(uid, voiceProfileBytes);
    } on ServerException {
      throw const ServerException('Failed to upload voice profile.');
    }
  }

  @override
  Future<List<int>?> getCachedVoiceProfileData() async {
    return await localDataSource.getVoiceProfileData();
  }

  @override
  Future<List<int>?> downloadUserVoiceProfile(String uid) async {
    return await remoteDataSource.downloadUserVoiceProfile(uid);
  }

  @override
  Future<void> cacheVoiceProfileData(List<int> voiceProfileBytes) async {
    await localDataSource.cacheVoiceProfileData(voiceProfileBytes);
  }

  @override
  Future<UserEntity> getUserData(String uid) async {
    return await remoteDataSource.getUserData(uid);
  }

  @override
  Future<bool> isUserLoggedIn() async {
    return await localDataSource.isUserLoggedIn();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.cacheUserLoginStatus(false);
    // Also clear voice profile from native Java code
    await _clearVoiceProfileFromNative();
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

  // Clear voice profile from native Java code
  Future<void> _clearVoiceProfileFromNative() async {
    try {
      const platform = MethodChannel('nabd/voiceid');
      await platform.invokeMethod('resetEnrollment');
    } catch (e) {
      print('Failed to clear voice profile from native: $e');
    }
  }
}
