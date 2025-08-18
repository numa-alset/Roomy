import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import '../../../../core/providers/global_providers.dart';
import '../../domain/entities/user.dart';

/// DS Provider – gives you an AuthRemoteDs wired to the global Dio client.
final authRemoteDsProvider = Provider<AuthRemoteDs>((ref) {
  return AuthRemoteDs(ref.watch(dioClientProvider));
});

class AuthRemoteDs {
  final DioClient client;
  AuthRemoteDs(this.client);

  /// Calls POST /auth/mock-login and returns (token, User)
  Future<(String token, User user)> mockLogin(String username) async {
    final res =
        await client.postJson('/auth/mock-login', {'username': username});
    final user = User(
      id: (res['user'] as Map)['id'] as String,
      username: (res['user'] as Map)['username'] as String,
    );
    return (res['token'] as String, user);
  }
}
