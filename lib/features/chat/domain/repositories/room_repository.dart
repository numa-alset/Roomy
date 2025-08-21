import 'package:frontend/core/error/failure.dart';
import 'package:frontend/core/functional/result.dart';
import 'package:frontend/features/chat/domain/entities/room.dart';

abstract class RoomRepository {
  Future<Result<Failure, List<Room>>> getRooms();

}