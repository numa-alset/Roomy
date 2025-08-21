import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/error/failure.dart';
import 'package:frontend/core/functional/result.dart';
import 'package:frontend/features/chat/data/datasources/room_remote_ds.dart';
import 'package:frontend/features/chat/data/models/room_model.dart';
import 'package:frontend/features/chat/domain/entities/room.dart';
import 'package:frontend/features/chat/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDs remote;
  RoomRepositoryImpl(this.remote);

  @override
  Future<Result<Failure, List<Room>>> getRooms()async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      final mockRooms = [
        RoomModel(id: '101', name: 'Flutter Devs'),
        RoomModel(id: '102', name: 'Music Lovers'),
        RoomModel(id: '103', name: 'Gaming Hub'),
        RoomModel(id: '104', name: 'Study Group'),
        RoomModel(id: '105', name: 'Chill Zone'),
      ];
      return Ok(mockRooms);
      // final ack = await remote.getRooms();
      // if (ack['ok'] == true) {
      //   final m = RoomModel.fromList(
      //       ack["data"]);
      //   return Ok(m);
      // } else {
      //   return Err(Failure('Error Get Rooms'));
      // }
    } catch (e) {
      return Err(Failure(e.toString()));
    }
  }


}

final roomRepoProvider = Provider<RoomRepository>((ref) {
  final ds = ref.watch(RoomRemoteDsProvider); // <-- use the DS provider
  return RoomRepositoryImpl(ds);
});

class RoomState {
  final bool loading;
  final List<Room> rooms;
  final String? error;

  const RoomState({
    this.loading = false,
    this.rooms = const [],
    this.error,
  });

  RoomState copyWith({
    bool? loading,
    List<Room>? rooms,
    String? error,
  }) =>
      RoomState(
        loading: loading ?? this.loading,
        rooms: rooms ?? this.rooms,
        error: error,
      );
}

class RoomController extends StateNotifier<RoomState> {
  RoomController(this.ref) : super(const RoomState()){
    loadRooms();
  }
  final Ref ref;

  Future<void> loadRooms() async {
    state = state.copyWith(loading: true, error: null);
    final repo = ref.read(roomRepoProvider);

    final result = await repo.getRooms();

    result.fold(
          (failure) => state = state.copyWith(
        loading: false,
        error: failure.message,
      ),
          (rooms) => state = state.copyWith(
        loading: false,
        rooms: rooms,
      ),
    );
  }
}

final roomControllerProvider =
StateNotifierProvider<RoomController, RoomState>((ref) => RoomController(ref));
