import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/call_providers.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallPage extends ConsumerStatefulWidget {
  const CallPage({super.key});
  @override
  ConsumerState<CallPage> createState() => _CallPageState();
}

class _CallPageState extends ConsumerState<CallPage> {
  final _peerCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callControllerProvider);
    final ctrl = ref.read(callControllerProvider.notifier);
    final remote =
        ctrl.webrtc.remoteRenderer; // audio rendered via hidden RTCVideoView

    return Scaffold(
      appBar: AppBar(title: const Text('Voice Call')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
              controller: _peerCtrl,
              decoration: const InputDecoration(labelText: 'Peer userId')),
          const SizedBox(height: 12),
          Text('Status: ${state.status}  ${state.peer ?? ""}'),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(
                onPressed: () {
                  final to = _peerCtrl.text.trim();
                  if (to.isNotEmpty) ctrl.call(to);
                },
                child: const Text('Call')),
            const SizedBox(width: 12),
            ElevatedButton(
                onPressed: () => ctrl.hangup(), child: const Text('Hang up')),
          ]),
          // Invisible view to ensure remote audio is routed
          const SizedBox(height: 12),
          SizedBox(
              width: 1, height: 1, child: RTCVideoView(remote, mirror: false)),
        ]),
      ),
    );
  }
}
