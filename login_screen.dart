// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final cred = await _auth.signInWithGoogle();
      if (cred != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Background grid pattern
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _GridPainter(),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // Glowing logo
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentGlow,
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: AppTheme.accent, size: 32),
                  )
                      .animate()
                      .fadeIn(delay: 200.ms)
                      .slideY(begin: -0.3, curve: Curves.easeOut),

                  const SizedBox(height: 32),

                  Text(
                    'CRYPT\nTALK',
                    style: GoogleFonts.spaceMono(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 0.9,
                      letterSpacing: -1,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms)
                      .slideY(begin: 0.2, curve: Curves.easeOut),

                  const SizedBox(height: 16),

                  Text(
                    'Encode your messages.\nOnly your circle reads them.',
                    style: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const Spacer(flex: 3),

                  // Feature pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill('🔐 Custom Ciphers'),
                      _Pill('👥 Mutual Friends Only'),
                      _Pill('🤖 AI Suggestions'),
                      _Pill('📱 Any Chat App'),
                    ],
                  ).animate().fadeIn(delay: 700.ms),

                  const SizedBox(height: 40),

                  // Google Sign In button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: _loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: AppTheme.accent))
                        : OutlinedButton.icon(
                            onPressed: _signIn,
                            icon: Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata,
                                      color: AppTheme.accent),
                            ),
                            label: Text(
                              'Continue with Google',
                              style: GoogleFonts.spaceMono(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(
                                  color: AppTheme.accent, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                  ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.3),

                  const Spacer(),

                  Center(
                    child: Text(
                      'End-to-end cipher • No message storage',
                      style: GoogleFonts.spaceMono(
                          fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(2),
        color: AppTheme.card,
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(fontSize: 11, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1A26)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
