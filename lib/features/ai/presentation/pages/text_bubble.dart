import 'package:flutter/material.dart';

class TextBubble extends StatelessWidget {
  final String text;
  final String role;
  const TextBubble({super.key, required this.text, required this.role});

  @override
  Widget build(BuildContext context) {
    final isUser = role == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text),
      ),
    );
  }
}