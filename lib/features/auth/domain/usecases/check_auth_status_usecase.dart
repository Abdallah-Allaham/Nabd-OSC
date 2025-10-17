import '../repositories/auth_repository.dart';

class CheckAuthStatusUsecase {
  final AuthRepository repository;

  CheckAuthStatusUsecase({required this.repository});

  Future<bool> call() async {
    return await repository.isUserLoggedIn();
  }
}