  import '../../domain/entities/room.dart';

  class RoomModel extends Room {
    const RoomModel(
        {required super.id,
          required super.name});

    static RoomModel fromRow(Map<String, dynamic> r) => RoomModel(
        id: r['id'],
        name: r['name'],);
    Map<String, dynamic> toRow() => {
      'id': id,
      'name': name,
    };
    static List<RoomModel> fromList(List<dynamic> list) {
      return list
          .map((e) => RoomModel(
        id: e['id'],
        name: e['name'],
      ))
          .toList();
    }
  }