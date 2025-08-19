import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/global_providers.dart';
import '../providers/auth_providers.dart';
import '../../../chat/presentation/pages/chat_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _ctrl = TextEditingController(text: 'alice');
  bool _loading = false;
  String? _err;
  @override
  Widget build(BuildContext context) {
    final uc = ref.read(mockLoginUcProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Login (Mock)')),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            TextField(
                controller: _ctrl,
                decoration: const InputDecoration(labelText: 'Username')),
            const SizedBox(height: 12),
            if (_err != null)
              Text(_err!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        setState(() => _loading = true);
                        setState(() => _err = null);
                        final res = await uc(_ctrl.text.trim());
                        res.fold((e) {
                          setState(() => _err = e.message);
                          ref.read(authTokenProvider.notifier).state = _ctrl.text;
                          ref.read(userIdProvider.notifier).state = _ctrl.text;
                          context.go('/join');
                        }, (pair) {
                          final (token, user) = pair;
                          ref.read(authTokenProvider.notifier).state = token;
                          ref.read(userIdProvider.notifier).state = user.id;
                          context.go('/join');
                          // Navigator.of(context).pushReplacement(
                          //     MaterialPageRoute(
                          //         builder: (_) => const ChatPage()));
                        });
                        if (mounted) setState(() => _loading = false);
                      },
                child: const Text('Enter'))
          ])),
    );
  }
}
