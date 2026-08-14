import '../models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> signInWithBackendToken(String token);
  Future<AppUser> loginWithEmail(String email, String password);
  Future<void> signOut();
  Future<String?> getAccessToken();
}
