import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/io.dart';

class WebRTCService {
  final String roomId;
  final String selfId;
  late MediaStream _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};
  final Map<String, MediaStream> remoteStreams = {};
  late IOWebSocketChannel _channel;

  WebRTCService({required this.roomId, required this.selfId});

  Future<void> init() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _channel = IOWebSocketChannel.connect("ws://localhost:3000");

    _channel.stream.listen((event) async {
      final data = jsonDecode(event);
      final type = data['type'];

      switch (type) {
        case 'new-user':
          _createOffer(data['id']);
          break;

        case 'offer':
          await _handleOffer(data['from'], data['sdp']);
          break;

        case 'answer':
          await _peerConnections[data['from']]?.setRemoteDescription(
            RTCSessionDescription(data['sdp'], 'answer'),
          );
          break;

        case 'ice-candidate':
          final candidate = RTCIceCandidate(
            data['candidate']['candidate'],
            data['candidate']['sdpMid'],
            data['candidate']['sdpMLineIndex'],
          );
          await _peerConnections[data['from']]?.addCandidate(candidate);
          break;
      }
    });

    // join room
    _channel.sink.add(jsonEncode({'type': 'join', 'room': roomId, 'id': selfId}));
  }

  MediaStream get localStream => _localStream;

  Future<RTCPeerConnection> _createPeerConnection(String peerId) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    final pc = await createPeerConnection(config);

    // Add local audio
    _localStream.getTracks().forEach((track) {
      pc.addTrack(track, _localStream);
    });

    // Remote stream
    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteStreams[peerId] = event.streams[0];
      }
    };

    // ICE candidates
    pc.onIceCandidate = (candidate) {
      _channel.sink.add(jsonEncode({
        'type': 'ice-candidate',
        'from': selfId,
        'to': peerId,
        'candidate': candidate.toMap(),
      }));
    };

    _peerConnections[peerId] = pc;
    return pc;
  }

  Future<void> _createOffer(String peerId) async {
    final pc = await _createPeerConnection(peerId);
    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _channel.sink.add(jsonEncode({
      'type': 'offer',
      'from': selfId,
      'to': peerId,
      'sdp': offer.sdp,
    }));
  }

  Future<void> _handleOffer(String peerId, String sdp) async {
    final pc = await _createPeerConnection(peerId);
    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _channel.sink.add(jsonEncode({
      'type': 'answer',
      'from': selfId,
      'to': peerId,
      'sdp': answer.sdp,
    }));
  }

  void dispose() {
    _channel.sink.close();
    _localStream.dispose();
    for (var pc in _peerConnections.values) {
      pc.close();
    }
  }
}
