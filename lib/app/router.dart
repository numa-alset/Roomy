import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/ai/presentation/pages/ai_page.dart';
import 'package:frontend/features/chat/presentation/pages/join_screen.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/global_providers.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/call/presentation/pages/call_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authTokenProvider);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable:
        GoRouterRefreshStream(ref.watch(authTokenProvider.notifier).stream),
    redirect: (ctx, state) {
      print("auth");
      print(auth);
      final loggingIn = state.matchedLocation == '/login';
      if (auth == null && !loggingIn) return '/login';
      if (auth != null && loggingIn) return '/join';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/chat', builder: (_, state) {final roomid=state.extra as String;return ChatPage(roomId: roomid,selfId: auth!,);}),
      GoRoute(path: '/call', builder: (_, __) => const CallPage()),
      GoRoute(path: '/ai', builder: (_, __) => const AiPage()),
      GoRoute(path: '/join', builder: (_, __) =>  JoinScreen(selfCallerId: auth!)),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListener = () => notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final void Function() notifyListener;
  late final StreamSubscription _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
