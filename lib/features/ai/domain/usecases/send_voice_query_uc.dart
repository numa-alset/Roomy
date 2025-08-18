import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/ai_response.dart';
import '../repositories/ai_repository.dart';

class SendVoiceQueryUc {
  final AiRepository repo;
  SendVoiceQueryUc(this.repo);
  Future<Result<Failure, AiResponse>> call({
    required String filePath,
    void Function(int sent, int total)? onProgress,
  }) =>
      repo.sendVoice(filePath: filePath, onProgress: onProgress);
}
