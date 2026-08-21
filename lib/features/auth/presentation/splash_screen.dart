import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9FF),
      body: Stack(
        children: [
          // Background soft bottom gradient curve
          Positioned(
            bottom: -80,
            left: -40,
            right: -40,
            height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0.8),
                  radius: 0.9,
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.12),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const Spacer(flex: 1),

                  // High-Res 3D Briefcase Orbit Illustration Image
                  Flexible(
                    flex: 6,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240, maxWidth: 240),
                      child: Image.asset(
                        'assets/images/gmb_briefcase_3d.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackIllustration();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Brand Title: SocialHive
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Social',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Hive',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF6366F1),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sub-title
                  Text(
                    'GMB Management Made Simple',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Purple Accent Line
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Description Body
                  Text(
                    'Manage your Google My Business\nseamlessly and grow your audience.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF475569),
                      height: 1.45,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Circular Loading Progress
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                      backgroundColor: Color(0xFFEEECFF),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Loading Text
                  Text(
                    'Getting things ready...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6366F1),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'This will just take a moment.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          child: Container(
            width: 180,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFEEECFF),
              borderRadius: BorderRadius.all(Radius.elliptical(180, 40)),
            ),
          ),
        ),
        Positioned(
          bottom: 45,
          child: _build3DBriefcase(),
        ),
      ],
    );
  }

  // 3D Styled Briefcase Widget
  Widget _build3DBriefcase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          width: 50,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: const Color(0xFF6366F1), width: 3),
          ),
        ),
        // Briefcase Body
        Container(
          width: 140,
          height: 100,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF4F46E5),
                Color(0xFF4338CA),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Strap details
              Positioned(
                top: 25,
                child: Container(
                  width: 140,
                  height: 12,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              // Golden center lock badge
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: Color(0xFF78350F),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
