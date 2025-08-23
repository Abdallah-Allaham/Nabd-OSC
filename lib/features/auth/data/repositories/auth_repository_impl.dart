import 'package:flutter/foundation.dart';
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
  Future<bool> isUserLoggedIn() async {
    return await localDataSource.isUserLoggedIn();
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.logout();
    await localDataSource.cacheUserLoginStatus(false);
  }
}
