import '../repositories/auth_repository.dart';

class SignupUsecase {
  final AuthRepository repository;

  SignupUsecase({required this.repository});

  Future<void> call(String uid,String phoneNumber, String name, String voiceProfileData) async {
    await repository.signupUser(uid,phoneNumber, name,voiceProfileData);
  }
}