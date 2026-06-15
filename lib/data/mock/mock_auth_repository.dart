import 'dart:async';

import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  AppUser? _currentUser;

  @override
  Future<AppUser?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return _currentUser;
  }

  @override
  Future<AppUser> signInWithBackendToken(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _currentUser = const AppUser(
      id: 'u_001',
      name: 'Jalal User',
      email: 'jalal@gmail.com',
    );
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
