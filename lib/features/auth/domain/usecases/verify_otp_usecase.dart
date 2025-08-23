import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyOtpUsecase {
  final AuthRepository repository;

  VerifyOtpUsecase({required this.repository});

  Future<UserEntity> call(String otp) async {
    return await repository.verifyOtpAndLogin(otp);
  }
}