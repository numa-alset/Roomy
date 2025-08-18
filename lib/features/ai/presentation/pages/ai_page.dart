import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/providers/global_providers.dart';
import '../providers/ai_providers.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AiPage extends ConsumerStatefulWidget {
  const AiPage({super.key});
  @override
  ConsumerState<AiPage> createState() => _AiPageState();
}

class _AiPageState extends ConsumerState<AiPage> {
  final _rec = AudioRecorder(); // record 5.x
  final _player = AudioPlayer();
  String? _lastPath;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
        path: path
    );
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
    if (url != null && url.isNotEmpty) {
      final full = url.startsWith('http') ? url : '$base$url';
      await _player.setUrl(full);
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(aiControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Voice Assistant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(
              'Transcript:\n${s.transcript.isEmpty ? "(none yet)" : s.transcript}'),
          const SizedBox(height: 12),
          if (s.uploading)
            LinearProgressIndicator(
                value: s.progress > 0 && s.progress < 1 ? s.progress : null),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: Icon(s.recording ? Icons.stop : Icons.mic),
            label: Text(s.recording ? 'Stop & Send' : 'Start Recording'),
            onPressed: s.uploading
                ? null
                : () => s.recording ? _stopSend() : _startRec(),
          ),
          if (_lastPath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                  'Last file: ${_lastPath!.split(Platform.pathSeparator).last}',
                  style: const TextStyle(fontSize: 12)),
            ),
        ]),
      ),
    );
  }
}
