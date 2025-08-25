import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:frontend/core/network/websocket_rtc_constant.dart';
import 'package:web_socket_channel/io.dart';

typedef OnRemoteStream = void Function(String peerId, MediaStream stream);
typedef OnMessageReceived = void Function(String from, String message);

class WebRTCService {
  final String roomId;
  final String selfId;

  late MediaStream _localStream;
  MediaStream get localStream => _localStream;

  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> remoteStreams = {};
  final Map<String, RTCDataChannel> _dataChannels = {}; // optional if you keep P2P chat
  late IOWebSocketChannel _channel;

  /// callbacks
  OnMessageReceived? onMessageReceived;
  OnRemoteStream? onRemoteStream;
  void Function(String peerId)? onPeerLeft;

  WebRTCService({required this.roomId, required this.selfId});

  Future<void> init() async {
    // Get local audio
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    try {
      // Connect to WS server
      _channel = IOWebSocketChannel.connect(WebSocketRtcConstant.webSocketUrl);
      debugPrint("Connecting to WebSocket at ${WebSocketRtcConstant.webSocketUrl}");
    } catch (e) {
      debugPrint("WebSocket connection failed: $e");
      return;
    }

    // Listen for incoming messages
    _channel.stream.listen(
          (event) async {
        debugPrint(" WS event: $event");

        final data = jsonDecode(event);
        final type = data['type'];

        switch (type) {
          case WebSocketRtcConstant.newUserWebsocket:
            debugPrint(" New user joined: ${data['id']}");
            _createOffer(data['id']);
            break;

          case WebSocketRtcConstant.offerWebsocket:
            debugPrint("Received offer from: ${data['from']}");
            await _handleOffer(data['from'], data['sdp']);
            break;

          case WebSocketRtcConstant.answerWebsocket:
            debugPrint("Received answer from: ${data['from']}");
            await _peerConnections[data['from']]?.setRemoteDescription(
              RTCSessionDescription(data['sdp'], 'answer'),
            );
            break;

          case WebSocketRtcConstant.iceCandidateWebsocket:
            debugPrint("ICE candidate from: ${data['from']}");
            final candidate = RTCIceCandidate(
              data['candidate']?['candidate'],
              data['candidate']?['sdpMid'],
              data['candidate']?['sdpMLineIndex'],
            );
            await _peerConnections[data['from']]?.addCandidate(candidate);
            break;

          case WebSocketRtcConstant.chatWebsocket:
            final from = (data['from'] ?? 'unknown').toString();
            final text = (data['text'] ?? '').toString();
            debugPrint("Chat from $from: $text");
            onMessageReceived?.call(from, text);
            break;

          case WebSocketRtcConstant.userLeftWebsocket:
            debugPrint(" User left: ${data['id']}");
            _removePeer(data['id']);
            break;


          default:
            debugPrint("Unknown WS type: $type");
        }
      },
      onDone: () => debugPrint("WebSocket closed"),
      onError: (e) => debugPrint("WebSocket error: $e"),
    );

    // Join room
    debugPrint("Sending join room request: $roomId / $selfId");
    _channel.sink.add(jsonEncode({'type': WebSocketRtcConstant.joinWebsocket, 'room': roomId, 'id': selfId}));
  }


  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final config = {
      'iceServers': [
        {'urls': WebSocketRtcConstant.stunUrl},
      ]
    };

    final pc = await createPeerConnection(config);

    // Add local audio
    for (final track in _localStream.getTracks()) {
      await pc.addTrack(track, _localStream);
    }

    // Remote audio
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams[0];
        remoteStreams[peerId] = stream;
        onRemoteStream?.call(peerId, stream);
      }
    };

    // ICE candidates
    pc.onIceCandidate = (candidate) {
      _channel.sink.add(jsonEncode({
        'type': WebSocketRtcConstant.iceCandidateWebsocket,
        'from': selfId,
        'to': peerId,
        'candidate': candidate.toMap(),
        'room': roomId,
      }));
    };

    // OPTIONAL: DataChannel (P2P chat) — keep or remove
    if (selfId.compareTo(peerId) < 0) {
      final dc = await pc.createDataChannel("chat", RTCDataChannelInit());
      _setupDataChannel(peerId, dc);
      _dataChannels[peerId] = dc;
    }
    pc.onDataChannel = (dc) {
      _setupDataChannel(peerId, dc);
      _dataChannels[peerId] = dc;
    };

    _peerConnections[peerId] = pc;
    return pc;
  }

  void _setupDataChannel(String peerId, RTCDataChannel dc) {
    dc.onMessage = (msg) {
      // If you want to also surface P2P messages to UI:
      onMessageReceived?.call(peerId, msg.text);
    };
  }

  Future<void> _createOffer(String peerId) async {
    final pc = await _createPeerConnection(peerId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _channel.sink.add(jsonEncode({
      'type': WebSocketRtcConstant.offerWebsocket,
      'from': selfId,
      'to': peerId,
      'sdp': offer.sdp,
      'room': roomId,
    }));
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    final pc = await _createPeerConnection(peerId);
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _channel.sink.add(jsonEncode({
      'type': WebSocketRtcConstant.answerWebsocket,
      'from': selfId,
      'to': peerId,
      'sdp': answer.sdp,
      'room': roomId,
    }));
  }

  /// Send text message via the server (broadcast to room)
  void sendChat(String message) {
    _channel.sink.add(jsonEncode({
      'type': WebSocketRtcConstant.chatWebsocket,
      'room': roomId,
      'id': selfId,
      'text': message,
    }));
  }

  void _removePeer(String peerId) {
    _peerConnections[peerId]?.close();
    _peerConnections.remove(peerId);

    // If you store renderers per peer in UI, trigger UI to remove them there.
    remoteStreams[peerId]?.dispose();
    remoteStreams.remove(peerId);

    _dataChannels[peerId]?.close();
    _dataChannels.remove(peerId);
    // Notify UI
    onPeerLeft?.call(peerId);
  }

  void dispose() {
    _channel.sink.close();
    _localStream.dispose();
    for (var pc in _peerConnections.values) {
      pc.close();
    }
    for (var dc in _dataChannels.values) {
      dc.close();
    }
  }
}
