import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import '../../../../core/providers/global_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final RoomRemoteDsProvider = Provider<RoomRemoteDs>((ref) {
  return RoomRemoteDs(ref.watch(dioClientProvider));
});

class RoomRemoteDs {
  final DioClient client;
  RoomRemoteDs(this.client);

  Future<Map<String, dynamic>> getRooms() {
    return client.get(
      '/v1/ai/voice',
    );
  }
}
