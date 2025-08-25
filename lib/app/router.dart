import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_routes.dart';
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
    initialLocation: AppRoutes.loginPath,
    refreshListenable:
        GoRouterRefreshStream(ref.watch(authTokenProvider.notifier).stream),
    redirect: (ctx, state) {
      final loggingIn = state.matchedLocation == AppRoutes.loginPath;
      if (auth == null && !loggingIn) return AppRoutes.loginPath;
      if (auth != null && loggingIn) return AppRoutes.joinPath;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.loginPath, builder: (_, __) => const LoginPage()),
      GoRoute(path: AppRoutes.chatPath, builder: (_, state) {final roomId=state.extra as String;return ChatPage(roomId: roomId,selfId: auth!,);}),
      GoRoute(path: AppRoutes.callPath, builder: (_, __) => const CallPage()),
      GoRoute(path: AppRoutes.aiPath, builder: (_, __) => const AiPage()),
      GoRoute(path: AppRoutes.joinPath, builder: (_, __) =>  JoinScreen(selfCallerId: auth!)),
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
