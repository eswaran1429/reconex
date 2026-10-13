import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const String _key = 'auth_token';
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';

  final FlutterSecureStorage _storage;
  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (!_loaded) {
      _cached = await _storage.read(key: _key);
      _loaded = true;
    }
    return _cached;
  }

  Future<void> save(String token) async {
    await _storage.write(key: _key, value: token);
    _cached = token;
    _loaded = true;
  }

  Future<void> saveProfile({required String name, required String email}) async {
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _emailKey, value: email);
  }

  /// Null for sessions created before the profile was stored.
  Future<({String name, String email})?> readProfile() async {
    final name = await _storage.read(key: _nameKey);
    final email = await _storage.read(key: _emailKey);
    if (name == null || email == null) return null;
    return (name: name, email: email);
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _emailKey);
    _cached = null;
    _loaded = true;
  }
}
