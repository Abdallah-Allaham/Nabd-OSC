import '../../../../core/utils/secure_storage_helper.dart';
import '../../../../core/constants/app_constants.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheVoiceProfile(String voiceProfileData);
  Future<void> cacheVoiceProfileData(List<int> voiceProfileBytes);
  Future<String?> getVoiceProfile();
  Future<List<int>?> getVoiceProfileData();
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
  Future<void> cacheVoiceProfileData(List<int> voiceProfileBytes) async {
    await secureStorage.savePrefStringList(
        key: AppConstants.voiceProfileBytesKey, value: voiceProfileBytes.map((e) => e.toString()).toList());
  }

  @override
  Future<String?> getVoiceProfile() async {
    return await secureStorage.getPrefString(
        key: AppConstants.voiceProfileDataKey, defaultValue: '');
  }

  @override
  Future<List<int>?> getVoiceProfileData() async {
    try {
      final stringList = await secureStorage.getPrefStringList(
          key: AppConstants.voiceProfileBytesKey, defaultValue: []);
      if (stringList.isEmpty) return null;
      return stringList.map((e) => int.parse(e)).toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteVoiceProfile() async {
    await secureStorage.remove(key: AppConstants.voiceProfileDataKey);
    await secureStorage.remove(key: AppConstants.voiceProfileBytesKey);
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
      // Clear all user data on logout
      await secureStorage.remove(key: AppConstants.uidKey);
      await secureStorage.remove(key: AppConstants.nameKey);
      await secureStorage.remove(key: AppConstants.phoneKey);
      await secureStorage.remove(key: AppConstants.voiceProfileDataKey);
      await secureStorage.remove(key: AppConstants.voiceProfileBytesKey);
    }
  }
}
