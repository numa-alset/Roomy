import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import '../env/env.dart';

final baseUrlProvider = Provider<String>((_) => Env.backendBase);
final authTokenProvider = StateProvider<String?>((_) => null);
final userIdProvider = StateProvider<String?>((_) => null);

final dioClientProvider = Provider<DioClient>((ref) {
  final base = ref.watch(baseUrlProvider);
  // When token changes, provider rebuilds so interceptor always sees fresh token
  final token = ref.watch(authTokenProvider);
  return DioClient(
    baseUrl: base,
    getToken: () async => token,
  );
});
