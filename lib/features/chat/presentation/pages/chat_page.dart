import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/global_providers.dart';
import '../providers/chat_providers.dart';
import '../../../call/presentation/pages/call_page.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(userIdProvider) ?? 'me';
    final state = ref.watch(chatControllerProvider);
    final ctrl = ref.read(chatControllerProvider.notifier);
    final peerCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: Text('Chat (${me.substring(0, 6)}…)'), actions: [
        IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // Navigator.of(context)
              //     .push(MaterialPageRoute(builder: (_) => const CallPage()));
            })
      ]),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
                controller: peerCtrl,
                decoration: const InputDecoration(labelText: 'Peer userId'))),
        Expanded(
            child: ListView.builder(
          itemCount: state.messages.length,
          itemBuilder: (_, i) {
            final m = state.messages[i];
            final isMe = m.fromId == me;
            return ListTile(
              title: Text(m.text),
              subtitle: Text('${m.fromId.substring(0, 6)} • ${m.createdAt}'),
              trailing: isMe ? const Icon(Icons.person) : null,
            );
          },
        )),
        Row(children: [
          Expanded(
              child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
                controller: msgCtrl,
                decoration: const InputDecoration(hintText: 'Message')),
          )),
          IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                final to = peerCtrl.text.trim();
                final text = msgCtrl.text.trim();
                if (to.isEmpty || text.isEmpty || state.sending) return;
                ctrl.send(to, text);
                msgCtrl.clear();
              }),
          IconButton(
              icon: const Icon(Icons.record_voice_over),
              onPressed: () => context.push('/ai')),
        ])
      ]),
    );
  }
}
