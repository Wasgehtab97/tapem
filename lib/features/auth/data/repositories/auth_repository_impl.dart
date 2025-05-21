import 'package:tapem/features/auth/data/sources/firestore_auth_source.dart';
import 'package:tapem/features/auth/data/dtos/user_data_dto.dart';
import 'package:tapem/features/auth/domain/models/user_data.dart';
import 'package:tapem/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirestoreAuthSource _source;

  AuthRepositoryImpl([FirestoreAuthSource? src])
      : _source = src ?? FirestoreAuthSource();

  @override
  Future<UserData> login(String email, String password) async {
    final dto = await _source.login(email, password);
    return dto.toModel();
  }

  @override
  Future<UserData> register(
      String email, String password, String gymId) async {
    final dto = await _source.register(email, password, gymId);
    return dto.toModel();
  }

  @override
  Future<void> logout() => _source.logout();

  @override
  Future<UserData?> getCurrentUser() =>
      _source.getCurrentUser().then((dto) => dto?.toModel());
}
