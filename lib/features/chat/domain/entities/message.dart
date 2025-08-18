class Message {
  final String id, fromId, toId, text, createdAt;
  const Message(
      {required this.id,
      required this.fromId,
      required this.toId,
      required this.text,
      required this.createdAt});
}
