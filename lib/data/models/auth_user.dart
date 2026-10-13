import 'package:reconex/core/network/paginated.dart';

class AuthUser {
  final String id;
  final String name;
  final String email;
  final String token;
  final DateTime createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.token,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Json json) => AuthUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    token: json['token'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
