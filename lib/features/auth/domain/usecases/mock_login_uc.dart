import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class MockLoginUc {
  final AuthRepository repo;
  MockLoginUc(this.repo);
  Future<Result<Failure, (String token, User user)>> call(String username) =>
      repo.mockLogin(username);
}
