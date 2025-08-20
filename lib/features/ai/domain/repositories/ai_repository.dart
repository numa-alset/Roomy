import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/ai_response.dart';

abstract class AiRepository {
  Future<Result<Failure, AiResponse>> sendVoice({
    required String filePath,
    void Function(int sent, int total)? onProgress,
  });
  Future<Result<Failure, AiResponse>> sendText({
    required String text,
  });
}
