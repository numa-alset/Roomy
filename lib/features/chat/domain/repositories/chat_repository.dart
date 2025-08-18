import '../../../../core/functional/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Result<Failure, Message>> send(String to, String text);
  Stream<Message> incoming();
  Future<void> saveLocal(Message m);
  Future<List<Message>> listLocal();
}
