import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';


class VoiceBubble extends StatefulWidget {
  final String audioUrl;
  final String role;
  const VoiceBubble({super.key, required this.audioUrl, required this.role});

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  late AudioPlayer _player;
  bool _playing = false;
  bool _loading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    // listen for position and duration
    _player.positionStream.listen((pos) {
      setState(() => _position = pos);
    });
    _player.durationStream.listen((dur) {
      if (dur != null) setState(() => _duration = dur);
    });
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    try {
      if (_playing) {
         _player.pause();
        setState(() => _playing = false);
      } else {
        if (_duration == Duration.zero) {
          setState(() => _loading = true);


          final source = LockCachingAudioSource(Uri.parse(widget.audioUrl));

          await _player.setAudioSource(source);
          setState(() => _loading = false);
        }
        _player.play();
        setState(() => _playing = true);
      }
    } catch (e) {
      setState(() {
        _playing = false;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
    }
  }

  void _seekToRelative(double relative) {
    if (_duration.inMilliseconds > 0) {
      final newPos = _duration * relative;
      _player.seek(newPos);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
      widget.role == "user" ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
          widget.role == "user" ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: Icon(
                  _playing ? Icons.pause : Icons.play_arrow,
                  color: widget.role == "user" ? Colors.white : Colors.black,
                ),
                onPressed: _togglePlay,
              ),
            const SizedBox(width: 8),

            // progress bar
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box != null) {
                    final tapPos = details.localPosition.dx;
                    final relative = tapPos / box.size.width;
                    _seekToRelative(relative.clamp(0.0, 1.0));
                  }
                },
                child: LinearProgressIndicator(
                  value: _duration.inMilliseconds == 0
                      ? 0
                      : _position.inMilliseconds / _duration.inMilliseconds,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.role == "user" ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // duration text
            Text(
              _formatDuration(_position),
              style: TextStyle(
                fontSize: 12,
                color: widget.role == "user" ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, "0");
    final minutes = two(d.inMinutes.remainder(60));
    final seconds = two(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
