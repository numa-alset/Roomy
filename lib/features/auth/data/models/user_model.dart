import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({required super.id, required super.username});
  factory UserModel.fromJson(Map<String, dynamic> j) =>
      UserModel(id: j['id'] as String, username: j['username'] as String);
}
