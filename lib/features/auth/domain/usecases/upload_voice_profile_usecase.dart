import 'dart:typed_data';

import '../repositories/auth_repository.dart';

class UploadVoiceProfileUsecase {
  final AuthRepository authRepository;

  UploadVoiceProfileUsecase({
    required this.authRepository,
  });

  Future<String> call(String uid, Uint8List audioFile) async {
    final voiceProfileUrl = await authRepository.uploadVoiceProfile(uid, audioFile);
    return voiceProfileUrl;
  }
}
