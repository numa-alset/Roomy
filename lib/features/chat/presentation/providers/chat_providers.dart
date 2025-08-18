import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../data/datasources/chat_local_ds.dart';
import '../../data/datasources/chat_socket_ds.dart';
import '../../data/models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatSocketDs remote;
  final ChatLocalDs local;
  final String me;
  ChatRepositoryImpl(this.remote, this.local, this.me);

  @override
  Future<Result<Failure, Message>> send(String to, String text) async {
    try {
      final ack = await remote.send(to, text);
      if (ack['ok'] == true) {
        final m = MessageModel(
            id: ack['id'],
            fromId: me,
            toId: to,
            text: text,
            createdAt: ack['createdAt']);
        await local.upsert(m);
        return Ok(m);
      } else {
        return Err(Failure('Send failed'));
      }
    } catch (e) {
      return Err(Failure(e.toString()));
    }
  }

  @override
  Stream<Message> incoming() =>
      remote.incoming().map((j) => MessageModel.fromSocket(j, me));

  @override
  Future<void> saveLocal(Message m) => local.upsert(m as MessageModel);
  @override
  Future<List<Message>> listLocal() => local.listAll();
}

final socketServiceProvider = Provider<SocketService>((ref) {
  final base = ref.watch(baseUrlProvider);
  final token = ref.watch(authTokenProvider)!;
  return SocketService(baseUrl: base, token: token, path: '/ws');
});

final chatSocketDsProvider = Provider<ChatSocketDs>((ref) {
  final sock = ref.watch(socketServiceProvider);
  final ds = ChatSocketDs(sock)..connect();
  ref.onDispose(ds.dispose);
  return ds;
});

final chatRepoProvider = Provider<ChatRepository>((ref) {
  final me = ref.watch(userIdProvider)!;
  return ChatRepositoryImpl(ref.watch(chatSocketDsProvider), ChatLocalDs(), me);
});

class ChatState {
  final List<Message> messages;
  final bool sending;
  const ChatState({this.messages = const [], this.sending = false});
  ChatState copyWith({List<Message>? messages, bool? sending}) => ChatState(
      messages: messages ?? this.messages, sending: sending ?? this.sending);
}

class ChatController extends StateNotifier<ChatState> {
  final ChatRepository repo;
  late final StreamSubscription sub;
  ChatController(this.repo) : super(const ChatState()) {
    _init();
  }
  Future<void> _init() async {
    final local = await repo.listLocal();
    state = state.copyWith(messages: local);
    sub = repo.incoming().listen((m) async {
      await repo.saveLocal(m);
      state = state.copyWith(messages: [...state.messages, m]);
    });
  }

  Future<void> send(String to, String text) async {
    state = state.copyWith(sending: true);
    final r = await repo.send(to, text);
    r.fold((_) {}, (m) {
      state = state.copyWith(messages: [...state.messages, m]);
    });
    state = state.copyWith(sending: false);
  }

  @override
  void dispose() {
    sub.cancel();
    super.dispose();
  }
}

final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(chatRepoProvider));
});
