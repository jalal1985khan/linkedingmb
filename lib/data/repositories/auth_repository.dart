import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithBackendToken(String token);
  Future<void> signOut();
  Future<String?> getAccessToken();
}
