import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/env/env.dart';

class WebRtcPeer {
  RTCPeerConnection? pc;
  MediaStream? local;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  String? currentPeer;

  Future<void> init() async {
    await remoteRenderer.initialize();
    final config = {
      'iceServers': [
        {
          'urls': [Env.stunUrl]
        }
      ]
    };
    pc = await createPeerConnection(config);
    local = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});
    for (var t in local!.getTracks()) {
      pc!.addTrack(t, local!);
    }
    pc!.onTrack = (evt) async {
      if (evt.streams.isNotEmpty) {
        remoteRenderer.srcObject = evt.streams.first; // plays remote audio
      }
    };
  }

  Future<RTCSessionDescription> createOffer() async {
    final offer = await pc!.createOffer();
    await pc!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> createAnswer() async {
    final answer = await pc!.createAnswer();
    await pc!.setLocalDescription(answer);
    return answer;
  }

  Future<void> setRemote(Map<String, dynamic> sdp) async {
    await pc!
        .setRemoteDescription(RTCSessionDescription(sdp['sdp'], sdp['type']));
  }

  Future<void> addIce(Map<String, dynamic> c) async {
    await pc!.addCandidate(
        RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
  }

  void onIce(void Function(RTCIceCandidate) cb) {
    pc!.onIceCandidate = cb;
  }

  Future<void> close() async {
    try {
      local?.getTracks().forEach((t) => t.stop());
    } catch (_) {}
    await pc?.close();
    await remoteRenderer.dispose();
  }
}
