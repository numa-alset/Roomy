import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_response.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../domain/usecases/send_voice_query_uc.dart';
import '../../data/datasources/ai_remote_ds.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDs remote;
  AiRepositoryImpl(this.remote);

  @override
  Future<Result<Failure, AiResponse>> sendVoice({
    required String filePath,
    void Function(int, int)? onProgress,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      return Ok(AiResponse(
        text: "This is a fake AI response for voice",
        audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      ));
      // final res = await remote.sendVoice(
      //   filePath: filePath,
      //   cancelToken: CancelToken(), // could be passed in for cancel
      //   onProgress: onProgress,
      // );
      // final text = (res['text'] ?? '') as String;
      // final audioUrl = (res['audioUrl'] ?? '') as String;
      // if (audioUrl.isEmpty) return Err(Failure('No audioUrl from server'));
      // return Ok(AiResponse(text: text, audioUrl: audioUrl));
    } catch (e) {
      return Err(Failure(e.toString()));
    }
  }
  @override
  Future<Result<Failure, AiResponse>> sendText({required String text}) async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      return Ok(AiResponse(
        text: "This is a fake AI response for voice",
        audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      ));
      // final res = await remote.sendText(text: text);
      // final reply = (res['text'] ?? '') as String;
      // final audioUrl = (res['audioUrl'] ?? '') as String;
      // return Ok(AiResponse(text: reply, audioUrl: audioUrl));
    } catch (e) {
      return Err(Failure(e.toString()));
    }
  }
}

final aiRepoProvider = Provider<AiRepository>(
    (ref) => AiRepositoryImpl(ref.watch(aiRemoteDsProvider)));
final sendVoiceQueryUcProvider = Provider<SendVoiceQueryUc>(
    (ref) => SendVoiceQueryUc(ref.watch(aiRepoProvider)));

class AiState {
  final bool recording;
  final bool uploading;
  final double progress; // 0..1
  final String transcript;
  final String? audioUrl;

  const AiState({
    this.recording = false,
    this.uploading = false,
    this.progress = 0,
    this.transcript = '',
    this.audioUrl,
  });

  AiState copyWith({
    bool? recording,
    bool? uploading,
    double? progress,
    String? transcript,
    String? audioUrl,
  }) =>
      AiState(
        recording: recording ?? this.recording,
        uploading: uploading ?? this.uploading,
        progress: progress ?? this.progress,
        transcript: transcript ?? this.transcript,
        audioUrl: audioUrl ?? this.audioUrl,
      );
}

class AiController extends StateNotifier<AiState> {
  AiController(this.ref) : super(const AiState());
  final Ref ref;

  Future<void> setRecording(bool v) async =>
      state = state.copyWith(recording: v);

  Future<void> uploadFile(String path) async {
    final uc = ref.read(sendVoiceQueryUcProvider);
    state = state.copyWith(uploading: true, progress: 0);
    final r = await uc(
        filePath: path,
        onProgress: (sent, total) {
          if (total > 0) state = state.copyWith(progress: sent / total);
        });
    r.fold(
      (e) => state =
          state.copyWith(uploading: false, transcript: 'Error: ${e.message}'),
      (ok) => state = state.copyWith(
          uploading: false, transcript: ok.text, audioUrl: ok.audioUrl),
    );
  }
  Future<Result<Failure, AiResponse>> sendText(String text) {
    return ref.read(aiRepoProvider).sendText(text: text);
  }
}

final aiControllerProvider =
    StateNotifierProvider<AiController, AiState>((ref) => AiController(ref));
