import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel(
      {required super.id,
      required super.fromId,
      required super.toId,
      required super.text,
      required super.createdAt});
  factory MessageModel.fromSocket(Map<String, dynamic> j, String me) =>
      MessageModel(
          id: j['id'],
          fromId: j['from'],
          toId: me,
          text: j['text'],
          createdAt: j['createdAt']);
  Map<String, dynamic> toRow() => {
        'id': id,
        'fromId': fromId,
        'toId': toId,
        'text': text,
        'createdAt': createdAt
      };
  static MessageModel fromRow(Map<String, dynamic> r) => MessageModel(
      id: r['id'],
      fromId: r['fromId'],
      toId: r['toId'],
      text: r['text'],
      createdAt: r['createdAt']);
}
