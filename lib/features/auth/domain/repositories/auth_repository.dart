import '../models/user_data.dart';

abstract class AuthRepository {
  Future<UserData> login(String email, String password);
  Future<UserData> register(
      String email, String password, String gymId);
  Future<void> logout();
  Future<UserData?> getCurrentUser();
  Future<void> setUsername(String userId, String username);
  Future<bool> isUsernameAvailable(String username);
}
