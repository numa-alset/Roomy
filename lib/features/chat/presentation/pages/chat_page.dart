import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/core/services/webrtc_service.dart';

class ChatPage extends StatefulWidget {
  final String roomId;
  final String selfId;

  const ChatPage({super.key, required this.roomId, required this.selfId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late WebRTCService _webrtcService;
  final TextEditingController _chatController = TextEditingController();
  final List<String> messages = [];
  final Map<String, RTCVideoRenderer> remoteRenderers = {};
  late RTCVideoRenderer _localRenderer;
  bool _micOn = true;

  @override
  void initState() {
    super.initState();
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    _webrtcService = WebRTCService(
      roomId: widget.roomId,
      selfId: widget.selfId,
    );
    _webrtcService.onMessageReceived = (from, msg) {
      setState(() => messages.add("$from: $msg"));
    };
    await _webrtcService.init();

    // Setup local renderer
    _localRenderer = RTCVideoRenderer();
    await _localRenderer.initialize();
    _localRenderer.srcObject = _webrtcService.localStream;

    // Listen for remote streams
    _webrtcService.remoteStreams.forEach((peerId, stream) async {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = stream;
      remoteRenderers[peerId] = renderer;
      setState(() {});
    });
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    _webrtcService.sendMessage(text);
    setState(() => messages.add("Me: $text"));
    _chatController.clear();
  }

  void _toggleMic() {
    setState(() => _micOn = !_micOn);
    _webrtcService.localStream.getAudioTracks().forEach((track) {
      track.enabled = _micOn;
    });
  }

  @override
  void dispose() {
    for (var r in remoteRenderers.values) {
      r.dispose();
    }
    _localRenderer.dispose();
    _webrtcService.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${widget.roomId}"),
        actions: [
          IconButton(
            icon: Icon(_micOn ? Icons.mic : Icons.mic_off),
            onPressed: _toggleMic,
          ),
          IconButton(
            icon: const Icon(Icons.call_end, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Audio grid
          Expanded(
            flex: 2,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: remoteRenderers.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return RTCVideoView(_localRenderer, mirror: true);
                final renderer = remoteRenderers.values.elementAt(index - 1);
                return RTCVideoView(renderer);
              },
            ),
          ),
          const Divider(height: 1),
          // Chat area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) => Align(
                      alignment: messages[i].startsWith("Me:")
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: messages[i].startsWith("Me:") ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          messages[i],
                          style: TextStyle(
                            color: messages[i].startsWith("Me:") ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
