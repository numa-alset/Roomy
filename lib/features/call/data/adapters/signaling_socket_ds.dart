import '../../../../core/network/socket_service.dart';

class SignalingSocketDs {
  final SocketService sock;
  SignalingSocketDs(this.sock) {
    sock.connect();
  }
  void onOffer(void Function(Map<String, dynamic>) cb) =>
      sock.on('webrtc:offer', (d) => cb(Map<String, dynamic>.from(d)));
  void onAnswer(void Function(Map<String, dynamic>) cb) =>
      sock.on('webrtc:answer', (d) => cb(Map<String, dynamic>.from(d)));
  void onIce(void Function(Map<String, dynamic>) cb) =>
      sock.on('webrtc:ice', (d) => cb(Map<String, dynamic>.from(d)));
  void sendOffer(String to, Map<String, dynamic> sdp) =>
      sock.emit('webrtc:offer', {'to': to, 'sdp': sdp});
  void sendAnswer(String to, Map<String, dynamic> sdp) =>
      sock.emit('webrtc:answer', {'to': to, 'sdp': sdp});
  void sendIce(String to, Map<String, dynamic> candidate) =>
      sock.emit('webrtc:ice', {'to': to, 'candidate': candidate});
  void dispose() => sock.dispose();
}
