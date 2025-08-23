import '../repositories/auth_repository.dart';

class CheckIfUserExistsUsecase {
  final AuthRepository repository;

  CheckIfUserExistsUsecase({required this.repository});

  Future<bool> call(String phoneNumber) async {
    return await repository.checkIfUserExists(phoneNumber);
  }
}