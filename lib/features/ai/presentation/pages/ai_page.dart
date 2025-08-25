import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/ai/presentation/pages/loading_bubble.dart';
import 'package:frontend/features/ai/presentation/pages/text_bubble.dart';
import 'package:frontend/features/ai/presentation/pages/voice_bubble.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/providers/global_providers.dart';
import '../providers/ai_providers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});
  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final _rec = AudioRecorder();
  final _player = AudioPlayer();
  int? _playingIndex;
  String? _lastPath;
  bool _sending = false;
  bool _loading = false;
  final _textCtrl = TextEditingController();
  final List<ChatMessage> _chat = [];

  @override
  void initState() {
    // TODO: implement initState

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle) {
        setState(() {
          _playingIndex = null;
          _loading = false;
        });
      }
    });
    super.initState();
  }
  @override
  void dispose() {
    _player.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _playVoice(String url, int index) async {
    try {
      if (_playingIndex == index) {
        await _player.stop();
        setState(() {
          _playingIndex = null;
          _loading = false;
        });
        return;
      }

      setState(() {
        _loading = true;
        _playingIndex = index;
      });

      final audioSource = LockCachingAudioSource(Uri.parse(url));
      await _player.setAudioSource(audioSource);
      await _player.play();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _playingIndex = null;
        _loading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Audio error: $e")));
    }
  }
    Future<String> _getSafePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
    return p.join(dir.path, fileName);
  }

  Future<void> _startRec() async {
    if (!await _rec.hasPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Mic permission denied')));
      return;
    }
    final path = _lastPath ?? await _getSafePath();
    await _rec.start(
        const RecordConfig(
            encoder: AudioEncoder.aacLc, sampleRate: 44100, bitRate: 128000),
        path: path);
    _lastPath = path;
    ref.read(aiControllerProvider.notifier).setRecording(true);
  }

  Future<void> _stopSend() async {
    final path = await _rec.stop();
    ref.read(aiControllerProvider.notifier).setRecording(false);
    if (path == null) return;
    _lastPath = path;
    await ref.read(aiControllerProvider.notifier).uploadFile(path);
    final state = ref.read(aiControllerProvider);
    final base = ref.read(baseUrlProvider);
    final url = state.audioUrl;

    _chat.add(ChatMessage(
        role: "user", text: "(voice message)", audioUrl: _lastPath, isVoice: true));
    _chat.add(ChatMessage(
        role: "ai", text: state.transcript, audioUrl: url, isVoice: url != null));
    _chat.add(ChatMessage(
        role: "ai", text: state.transcript, audioUrl: url, isVoice: false));
    setState(() {});

    if (url != null && url.isNotEmpty) {
      final full = url.startsWith('http') ? url : '$base$url';
      await _player.setUrl(full);
      // await _player.play();
    }
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    FocusScope.of(context).unfocus();
    _sending = true;
    // 1️⃣ Add user message
    _chat.add(ChatMessage(role: "user", text: text));
    // 2️⃣ Add temporary loading message
    final loadingIndex = _chat.length;
    _chat.add(ChatMessage(role: "ai", text: "loading...", isVoice: false));
    setState(() {});

    // 3️⃣ Send request
    final r = await ref.read(aiControllerProvider.notifier).sendText(text);
    r.fold(
          (e) {
        _chat[loadingIndex] =
            ChatMessage(role: "ai", text: "Error: ${e.message}");
        setState(() {_sending = false;});
      },
          (ok) async {
        _chat[loadingIndex] = ChatMessage(
            role: "ai", text: ok.text, audioUrl: ok.audioUrl, isVoice: ok.audioUrl.isNotEmpty);
        _chat.add(ChatMessage(
            role: "ai", text: ok.text, audioUrl: ok.audioUrl, isVoice: false));
        setState(() {_sending = false;});

        if (ok.audioUrl.isNotEmpty) {
          final base = ref.read(baseUrlProvider);
          final full = ok.audioUrl.startsWith('http')
              ? ok.audioUrl
              : '$base${ok.audioUrl}';
          await _player.setUrl(full);
          // await _player.play();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(aiControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Voice Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _chat.length,
              itemBuilder: (context, index) {
                final msg = _chat[index];
                if (msg.text == "loading...") {
                  return const LoadingBubble(role: "ai");
                } else if (msg.isVoice && msg.audioUrl != null) {
                  return VoiceBubble(
                    audioUrl: msg.audioUrl!,
                    role: msg.role,
                    // isPlaying: _playingIndex == index,
                    // isLoading: _loading && _playingIndex == index,
                    // onTap: () => _playVoice(msg.audioUrl!, index),
                  );
                } else {
                  return TextBubble(text: msg.text, role: msg.role);
                }
              },
            ),
          ),
          if (s.uploading)
            LinearProgressIndicator(
                value: s.progress > 0 && s.progress < 1 ? s.progress : null),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  decoration: const InputDecoration(
                    hintText: "Type a message",
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: (s.uploading||_sending) ? null : _sendText,
              ),
              IconButton(
                icon: Icon(s.recording ? Icons.stop : Icons.mic),
                onPressed: (s.uploading||_sending)
                    ? null
                    : () => s.recording ? _stopSend() : _startRec(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class ChatMessage {
  final String role; // "user" or "ai"
  final String text;
  final String? audioUrl;
  final bool isVoice;

  ChatMessage({
    required this.role,
    required this.text,
    this.audioUrl,
    this.isVoice = false,
  });
}