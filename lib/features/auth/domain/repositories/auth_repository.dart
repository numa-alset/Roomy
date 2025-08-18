import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Result<Failure, (String token, User user)>> mockLogin(String username);
}
