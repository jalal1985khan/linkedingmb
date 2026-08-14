import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/auth_provider.dart';
import 'email_login_screen.dart';
import 'in_app_google_auth_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: Stack(
        children: [
          // Bottom subtle gradient curve
          Positioned(
            bottom: -60,
            left: -40,
            right: -40,
            height: 280,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.9),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.12),
                    const Color(0xFF8B5CF6).withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Top 3D Hero Illustration (Cropped Rocket, Storefront, Cards, Clouds)
                  Expanded(
                    flex: 9,
                    child: Center(
                      child: Image.asset(
                        'assets/images/login_hero_3d.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackRocketIllustration();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Headline: Welcome to SocialHive
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Welcome to ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'SocialHive',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6366F1),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sub-description
                  Text(
                    'Manage your Google My Business\nseamlessly and grow your audience.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 3 Columns: Insights, Engage, Grow with 3D Icons
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFeatureColumn(
                          assetPath: 'assets/images/icon_insights_3d.png',
                          fallbackIcon: Icons.bar_chart_rounded,
                          title: 'Insights',
                          description: 'Track performance and understand your audience.',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 75,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color(0xFFF1F5F9),
                      ),
                      Expanded(
                        child: _buildFeatureColumn(
                          assetPath: 'assets/images/icon_engage_3d.png',
                          fallbackIcon: Icons.campaign_rounded,
                          title: 'Engage',
                          description: 'Connect with customers and build relationships.',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 75,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color(0xFFF1F5F9),
                      ),
                      Expanded(
                        child: _buildFeatureColumn(
                          assetPath: 'assets/images/icon_grow_3d.png',
                          fallbackIcon: Icons.shield_outlined,
                          title: 'Grow',
                          description: 'Boost your visibility and grow your business.',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF991B1B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Button: Continue with Google
                  if (authState.isInitializing)
                    const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5B4DFF),
                            Color(0xFF4338CA),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4338CA).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            if (!kIsWeb) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const InAppGoogleAuthScreen(),
                                ),
                              );
                            } else {
                              ref.read(authProvider.notifier).loginWithGoogle();
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                _build3DGoogleIcon(),
                                const Expanded(
                                  child: Text(
                                    'Continue with Google',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),



                  const SizedBox(height: 16),

                  // Option to login using Email & Password
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EmailLoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.mail_outline_rounded,
                        size: 16,
                        color: Color(0xFF4945FF),
                      ),
                      label: Text(
                        'Log in using Email',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4945FF),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Trust Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Secure & trusted by Google',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feature Column Item Widget with 3D Image Asset
  Widget _buildFeatureColumn({
    required String assetPath,
    required IconData fallbackIcon,
    required String title,
    required String description,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 64,
          height: 72,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  fallbackIcon,
                  size: 24,
                  color: const Color(0xFF6366F1),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // 3D Google Icon Badge Widget
  Widget _build3DGoogleIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(22, 22),
          painter: _GoogleGLogoPainter(),
        ),
      ),
    );
  }

  // Fallback Rocket Widget
  Widget _buildFallbackRocketIllustration() {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F0FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.rocket_launch_rounded,
        size: 70,
        color: Color(0xFF6366F1),
      ),
    );
  }
}

// Crisp Vector Painter for Google 'G' Logo
class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w / 2;
    final double strokeWidth = w * 0.24;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: radius - strokeWidth / 2,
    );

    // Blue arc (Right & Top-Right)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, -0.4, 1.7, false, bluePaint);

    // Green arc (Bottom)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 1.3, 1.2, false, greenPaint);

    // Yellow arc (Bottom-Left)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 2.5, 0.9, false, yellowPaint);

    // Red arc (Top-Left)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 3.4, 1.3, false, redPaint);

    // Blue horizontal bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      cx - 1,
      cy - strokeWidth / 2,
      radius + 1,
      strokeWidth,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


