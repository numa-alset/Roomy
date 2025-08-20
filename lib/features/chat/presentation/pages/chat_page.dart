import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/core/services/webrtc_service.dart';
import 'package:go_router/go_router.dart';


class ChatPage extends StatefulWidget {
  final String roomId;
  final String selfId;
  const ChatPage({super.key, required this.roomId, required this.selfId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late WebRTCService _svc;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final Map<String, RTCVideoRenderer> _remoteRenderers = {};
  final List<String> _messages = [];
  final _msgCtrl = TextEditingController();
  bool _micOn = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _svc = WebRTCService(roomId: widget.roomId, selfId: widget.selfId);

    _svc.onMessageReceived = (from, text) {
      setState(() => _messages.add("${from == widget.selfId ? "Me" : from}: $text"));
    };

    _svc.onRemoteStream = (peerId, stream) async {
      final r = RTCVideoRenderer();
      await r.initialize();
      r.srcObject = stream;
      setState(() => _remoteRenderers[peerId] = r);
    };

    _svc.onPeerLeft = (peerId) {
      setState(() {
        _remoteRenderers[peerId]?.dispose();
        _remoteRenderers.remove(peerId);
      });
    };
    await _svc.init();

    await _localRenderer.initialize();
    _localRenderer.srcObject = _svc.localStream;
    setState(() {});
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _localRenderer.dispose();
    for (final r in _remoteRenderers.values) {
      r.dispose();
    }
    _svc.dispose();
    super.dispose();
  }

  void _toggleMic() {
    setState(() => _micOn = !_micOn);
    for (final t in _svc.localStream.getAudioTracks()) {
      t.enabled = _micOn;
    }
  }

  void _send() {
    final txt = _msgCtrl.text.trim();
    if (txt.isEmpty) return;
    _svc.sendChat(txt);
    _msgCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      // local (audio-only; still needs a renderer to play)
      if (_localRenderer.textureId != null)
        Card(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_micOn ? Icons.mic : Icons.mic_off, size: 36),
              const SizedBox(height: 8),
              Text(widget.selfId),
            ],
          ),
        ),
      // remotes
      ..._remoteRenderers.entries.map((e) => Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hearing, size: 36),
            const SizedBox(height: 8),
            Text("Peer: ${e.key}"),
            // Note: audio plays even if you don't show the RTCVideoView.
            // If you want to keep it invisible, you can comment it out.
            SizedBox(height: 1, width: 1, child: RTCVideoView(e.value)),
          ],
        ),
      )),
    ];

    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsetsGeometry.only(bottom: 40),
        child: FloatingActionButton(onPressed: () {
context.push("/ai");
        },
        child: Icon(Icons.question_mark),

        ),
      ),floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: Text("Room ${widget.roomId}"),
        actions: [
          IconButton(
            icon: Icon(_micOn ? Icons.mic : Icons.mic_off),
            onPressed: _toggleMic,
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () { _svc.dispose(); context.go('/join');},
          ),
        ],
      ),
      body: Column(
        children: [
          // Voice tiles (audio-only)
          Expanded(
            // flex: 2,
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(8),
              children: tiles,
            ),
          ),
          const Divider(height: 1),
          // Chat
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (_, i) {
                        final mine = _messages[i].startsWith("Me:");
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: mine ? Colors.blueAccent : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _messages[i],
                              style: TextStyle(color: mine ? Colors.white : Colors.black),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgCtrl,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.send), onPressed: _send),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
