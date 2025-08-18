import 'dart:async';
import '../../../../core/network/socket_service.dart';

class ChatSocketDs {
  final SocketService sock;
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  ChatSocketDs(this.sock);
  void connect() {
    sock.connect();
    sock.on('chat:message',
        (data) => _incoming.add(Map<String, dynamic>.from(data)));
  }

  Future<Map<String, dynamic>> send(String to, String text) async {
    final c = Completer<Map<String, dynamic>>();
    sock.emitAck('chat:message', {'to': to, 'text': text}, (ack) {
      c.complete(Map<String, dynamic>.from(ack ?? {}));
    });
    return c.future;
  }

  Stream<Map<String, dynamic>> incoming() => _incoming.stream;
  void dispose() {
    _incoming.close();
    sock.dispose();
  }
}
