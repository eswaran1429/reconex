import 'package:reconex/core/network/api_client.dart';
import 'package:reconex/core/network/paginated.dart';
import 'package:reconex/core/storage/token_storage.dart';
import 'package:reconex/data/models/auth_user.dart';

class AuthService {
  AuthService(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  Future<AuthUser> register({required String name, required String email, required String password}) async {
    final data = await _api.post('/auth/register', data: {'name': name, 'email': email, 'password': password});
    return AuthUser.fromJson(data as Json);
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', data: {'email': email, 'password': password});
    final user = AuthUser.fromJson(data as Json);
    await _tokenStorage.save(user.token);
    await _tokenStorage.saveProfile(name: user.name, email: user.email);
    print('Login token: ${user.token}');
    return user;
  }

  Future<bool> isLoggedIn() async => await _tokenStorage.read() != null;

  Future<({String name, String email})?> currentUser() => _tokenStorage.readProfile();

  Future<void> logout() => _tokenStorage.clear();
}
