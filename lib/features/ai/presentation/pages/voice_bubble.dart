import 'package:flutter/material.dart';

class VoiceBubble extends StatelessWidget {
  final String audioUrl;
  final String role;
  final bool isPlaying;
  final VoidCallback onTap;

  const VoiceBubble({
    super.key,
    required this.audioUrl,
    required this.role,
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: role == "user" ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: role == "user" ? Colors.blueAccent : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isPlaying ? Icons.stop : Icons.play_arrow,
                  color: role == "user" ? Colors.white : Colors.black),
              const SizedBox(width: 8),
              Text(isPlaying ? "Playing..." : "Voice message",
                  style: TextStyle(
                      color: role == "user" ? Colors.white : Colors.black)),
            ],
          ),
        ),
      ),
    );
  }
}
