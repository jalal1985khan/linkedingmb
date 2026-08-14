import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/api_config.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/backend_auth_repository.dart';
import '../../../data/repositories/backend_business_repository.dart';

class AuthState {
  final bool isInitializing;
  final bool isAuthenticated;
  final bool hasBusinessProfile;
  final AppUser? user;
  final String? errorMessage;

  const AuthState({
    this.isInitializing = true,
    this.isAuthenticated = false,
    this.hasBusinessProfile = false,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isInitializing,
    bool? isAuthenticated,
    bool? hasBusinessProfile,
    AppUser? user,
    String? errorMessage,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      hasBusinessProfile: hasBusinessProfile ?? this.hasBusinessProfile,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final backendAuthRepoProvider = Provider((ref) => BackendAuthRepository());
final backendBusinessRepoProvider = Provider((ref) => BackendBusinessRepository());

class AuthNotifier extends StateNotifier<AuthState> {
  final BackendAuthRepository _authRepo;
  final BackendBusinessRepository _businessRepo;

  AuthNotifier(this._authRepo, this._businessRepo) : super(const AuthState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1. Check if token exists on Web URL query parameters (e.g. ?token=XYZ)
      if (kIsWeb) {
        final currentUri = Uri.base;
        final urlToken = currentUri.queryParameters['token'];
        if (urlToken != null && urlToken.isNotEmpty) {
          await authenticateWithToken(urlToken);
          return;
        }
      }

      // 2. Check stored JWT token in secure storage
      final user = await _authRepo.getCurrentUser();
      if (user != null) {
        final hasBusiness = await _checkBusinessProfile(user.id);
        state = state.copyWith(
          isInitializing: false,
          isAuthenticated: true,
          hasBusinessProfile: hasBusiness,
          user: user,
          errorMessage: null,
        );
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Auth initialization error: $e');
    }

    state = state.copyWith(
      isInitializing: false,
      isAuthenticated: false,
      hasBusinessProfile: false,
      user: null,
    );
  }

  /// Initiate Google Login via production backend API
  Future<void> loginWithGoogle() async {
    try {
      state = state.copyWith(isInitializing: true, errorMessage: null);

      String loginUrl;
      if (kIsWeb) {
        // On Web, call standard endpoint without mobile_redirect_uri
        // to pass remote production server (api.socialhive.pro) validation
        loginUrl = '${ApiConfig.baseUrl}/api/auth/google/login';
      } else {
        // On Mobile (iOS/Android), call mobile endpoint pre-configured for socialhivegmb://auth-callback
        loginUrl = '${ApiConfig.baseUrl}/api/auth/google/mobile/login';
      }

      final uri = Uri.parse(loginUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch Google Sign-In URL');
      }
    } catch (e) {
      debugPrint('❌ Google Login failed: $e');
      state = state.copyWith(
        isInitializing: false,
        errorMessage: 'Google Sign-In failed. Please try again.',
      );
    }
  }

  /// Login using Email & Password via backend API
  Future<void> loginWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isInitializing: true, errorMessage: null);
      final user = await _authRepo.loginWithEmail(email, password);
      final hasBusiness = await _checkBusinessProfile(user.id);
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: true,
        hasBusinessProfile: hasBusiness,
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('❌ Email Login failed: $e');
      state = state.copyWith(
        isInitializing: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Authenticate user using JWT token returned from production Google OAuth callback
  Future<void> authenticateWithToken(String token) async {
    try {
      state = state.copyWith(isInitializing: true, errorMessage: null);

      final user = await _authRepo.signInWithBackendToken(token);
      final hasBusiness = await _checkBusinessProfile(user.id);

      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: true,
        hasBusinessProfile: hasBusiness,
        user: user,
        errorMessage: null,
      );
    } catch (e) {
      debugPrint('❌ Token authentication failed: $e');
      await _authRepo.signOut();
      state = state.copyWith(
        isInitializing: false,
        isAuthenticated: false,
        hasBusinessProfile: false,
        user: null,
        errorMessage: 'Authentication session expired. Please sign in again.',
      );
    }
  }

  Future<bool> _checkBusinessProfile(String userId) async {
    try {
      final businesses = await _businessRepo.getAssociatedBusinesses(userId);
      return businesses.isNotEmpty;
    } catch (e) {
      debugPrint('⚠️ Error checking business profile: $e');
      return false;
    }
  }

  void completeBusinessProfile() {
    state = state.copyWith(hasBusinessProfile: true);
  }

  Future<void> logout() async {
    await _authRepo.signOut();
    state = const AuthState(
      isInitializing: false,
      isAuthenticated: false,
      hasBusinessProfile: false,
      user: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepo = ref.watch(backendAuthRepoProvider);
  final businessRepo = ref.watch(backendBusinessRepoProvider);
  return AuthNotifier(authRepo, businessRepo);
});

