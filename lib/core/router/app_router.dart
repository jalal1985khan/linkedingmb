import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/business_flow/presentation/business_selection_screen.dart';
import '../../features/business_flow/presentation/onboarding_screen.dart';
import '../../features/shell/main_shell_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuth = authState.isAuthenticated;
      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final hasBusiness = authState.hasBusinessProfile;
      final isBusinessFlow = state.matchedLocation.startsWith('/business');
      final isInitializing = authState.isInitializing;

      if (isInitializing) {
        return isSplash ? null : '/splash';
      }

      if (!isAuth) {
        if (isLogin) return null;
        return '/login';
      }

      // User is authenticated
      if (isSplash || isLogin) {
        if (!hasBusiness) {
          return '/business/select';
        }
        return '/home';
      }

      if (isAuth && !hasBusiness && !isBusinessFlow) {
        return '/business/select';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/business/select',
        builder: (context, state) => const BusinessSelectionScreen(),
      ),
      GoRoute(
        path: '/business/onboarding',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return OnboardingScreen(initialData: args);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellScreen(),
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, _) => notifyListeners());
  }
}
