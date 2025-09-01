import '../../../../core/utils/secure_storage_helper.dart';
import '../../../../core/constants/app_constants.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheVoiceProfile(String voiceProfileData);
  Future<String?> getVoiceProfile();
  Future<void> deleteVoiceProfile();
  Future<bool> isUserLoggedIn();
  Future<void> cacheUserLoginStatus(bool isLoggedIn, {String? uid});
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorageHelper secureStorage;

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> cacheVoiceProfile(String voiceProfileData) async {
    await secureStorage.savePrefString(
        key: AppConstants.voiceProfileDataKey, value: voiceProfileData);
  }

  @override
  Future<String?> getVoiceProfile() async {
    return await secureStorage.getPrefString(
        key: AppConstants.voiceProfileDataKey, defaultValue: '');
  }

  @override
  Future<void> deleteVoiceProfile() async {
    await secureStorage.remove(key: AppConstants.voiceProfileDataKey);
  }

  @override
  Future<bool> isUserLoggedIn() async {
    String? uid = await secureStorage.getPrefString(key: AppConstants.uidKey, defaultValue: '');
    return uid != '';
  }

  @override
  Future<void> cacheUserLoginStatus(bool isLoggedIn, {String? uid}) async {
    if (isLoggedIn && uid != null) {
      await secureStorage.savePrefString(key: AppConstants.uidKey, value: uid);
    } else {
      await secureStorage.remove(key: AppConstants.uidKey);
    }
  }
}
