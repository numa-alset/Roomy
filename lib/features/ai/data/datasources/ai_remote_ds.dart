import 'package:dio/dio.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/api_url.dart';
import '../../../../core/providers/global_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiRemoteDsProvider = Provider<AiRemoteDs>((ref) {
  return AiRemoteDs(ref.watch(dioClientProvider));
});

class AiRemoteDs {
  final DioClient client;
  AiRemoteDs(this.client);

  /// Sends voice file to backend and expects { text, audioUrl }
  /// `fieldName` must match your backend (commonly 'file' or 'audio').
  Future<Map<String, dynamic>> sendVoice({
    required String filePath,
    String fieldName = 'file',
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) {
    return client.postMultipart(
      AppUrl.sendVoiceAiUrl,
      fieldName: fieldName,
      filePath: filePath,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );
  }
  Future<Map<String, dynamic>> sendText({
    required String text,
  }) {
    return client.postJson(
      AppUrl.sendTextAiUrl,
      {
      "text":text
      }
    );
  }
}
