import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class JoinScreen extends StatefulWidget {
  final String selfCallerId;

  const JoinScreen({super.key, required this.selfCallerId});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final roomIdController = TextEditingController();

  void _joinRoom() {
    final roomId = roomIdController.text.trim();
    if (roomId.isEmpty) return;

    context.go("/chat", extra: roomId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Join a Room"),
      ),
      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: TextEditingController(
                    text: widget.selfCallerId,
                  ),
                  readOnly: true,
                  textAlign: TextAlign.center,
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    labelText: "Your ID",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomIdController,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: "Enter Room ID",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                  ),
                  onPressed: _joinRoom,
                  child: const Text(
                    "Join Room",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
