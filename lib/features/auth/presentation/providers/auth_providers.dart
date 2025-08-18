import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/mock_login_uc.dart';
import '../../data/datasources/auth_remote_ds.dart'; // <-- make sure this import exists

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDs remote;
  AuthRepositoryImpl(this.remote);

  @override
  Future<Result<Failure, (String token, User user)>> mockLogin(
      String username) async {
    try {
      final (t, u) = await remote.mockLogin(username);
      return Ok((t, u));
    } catch (e) {
      return Err(Failure(e.toString()));
    }
  }
}

final authRepoProvider = Provider<AuthRepository>((ref) {
  final ds = ref.watch(authRemoteDsProvider); // <-- use the DS provider
  return AuthRepositoryImpl(ds);
});

final mockLoginUcProvider = Provider<MockLoginUc>((ref) {
  return MockLoginUc(ref.watch(authRepoProvider));
});
