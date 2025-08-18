abstract class CallRepository {
  Future<void> call(String peerUserId);
  Future<void> hangup();
}
