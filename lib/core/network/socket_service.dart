import 'package:socket_io_client/socket_io_client.dart' as io;

/// Reusable Socket.IO service used by Chat & Call features.
class SocketService {
  final String baseUrl;
  final String token;
  final String path;
  late final io.Socket socket;
  SocketService(
      {required this.baseUrl, required this.token, this.path = '/ws'}) {
    socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setPath(path)
            .setAuth({'token': token})
            .disableAutoConnect()
            .build());
  }
  void connect() => socket.connect();
  void on(String event, Function(dynamic) handler) => socket.on(event, handler);
  void off(String event) => socket.off(event);
  void emit(String event, dynamic data) => socket.emit(event, data);
  void emitAck(String event, dynamic data, void Function(dynamic)? ack) =>
      socket.emitWithAck(event, data, ack: ack);
  void dispose() => socket.dispose();
}
