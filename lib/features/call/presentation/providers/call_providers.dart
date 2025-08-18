import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/adapters/signaling_socket_ds.dart';
import '../../data/adapters/webrtc_peer.dart';

final signalingProvider = Provider<SignalingSocketDs>((ref) {
  final base = ref.watch(baseUrlProvider);
  final token = ref.watch(authTokenProvider)!;
  final sock = SocketService(baseUrl: base, token: token, path: '/ws');
  final sig = SignalingSocketDs(sock);
  ref.onDispose(sig.dispose);
  return sig;
});

class CallState {
  final String? peer;
  final String status;
  CallState({this.peer, this.status = 'idle'});
}

class CallController extends StateNotifier<CallState> {
  final SignalingSocketDs signaling;
  final WebRtcPeer webrtc = WebRtcPeer();
  CallController(this.signaling) : super(CallState()) {
    _init();
  }
  Future<void> _init() async {
    await webrtc.init();
    signaling.onOffer((d) async {
      state = CallState(peer: d['from'], status: 'ringing');
      await webrtc.setRemote(Map<String, dynamic>.from(d['sdp']));
      final answer = await webrtc.createAnswer();
      signaling.sendAnswer(d['from'], answer.toMap());
    });
    signaling.onAnswer((d) async {
      await webrtc.setRemote(Map<String, dynamic>.from(d['sdp']));
      state = CallState(peer: d['from'] ?? state.peer, status: 'connected');
    });
    signaling.onIce((d) async {
      await webrtc.addIce(Map<String, dynamic>.from(d['candidate']));
    });
    webrtc.onIce((c) {
      final to = state.peer;
      if (to != null && c.candidate != null) {
        signaling.sendIce(to, c.toMap());
      }
    });
  }

  Future<void> call(String peerId) async {
    state = CallState(peer: peerId, status: 'calling');
    final offer = await webrtc.createOffer();
    signaling.sendOffer(peerId, offer.toMap());
  }

  Future<void> hangup() async {
    await webrtc.close();
    state = CallState(status: 'idle');
  }
}

final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) {
  return CallController(ref.watch(signalingProvider));
});
