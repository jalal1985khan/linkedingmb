import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/business_flow/business_flow_controller.dart';
import '../features/business_flow/post_login_flow_screen.dart';
import '../features/shell/main_shell_screen.dart';

class GmbAiApp extends ConsumerWidget {
  const GmbAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final selectedBusiness = ref.watch(selectedBusinessProvider);

    return MaterialApp(
      title: 'SocialHIveGMB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.when(
        loading: () => const _SplashScreen(),
        error: (error, stackTrace) => const LoginScreen(),
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          if (selectedBusiness == null) {
            return const PostLoginFlowScreen();
          }
          return const MainShellScreen();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'GMB',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
