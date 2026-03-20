// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final fs = FirestoreService();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('PROFILE')),
      body: StreamBuilder<AppUser>(
        stream: fs.watchCurrentUser(),
        builder: (ctx, snap) {
          final user = snap.data;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: AppTheme.accentGlow, blurRadius: 24)
                        ],
                      ),
                      child: user?.photoUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(user!.photoUrl!))
                          : CircleAvatar(
                              backgroundColor: AppTheme.card,
                              child: Text(
                                (user?.displayName ?? '?')[0].toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                    color: AppTheme.accent, fontSize: 36),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user?.displayName ?? '...',
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: GoogleFonts.spaceMono(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),

              const SizedBox(height: 40),
              const Divider(color: AppTheme.border),

              _InfoRow('UID', user?.uid ?? '...'),
              _InfoRow('Friends', '${user?.friendUids.length ?? 0}'),
              _InfoRow('Active Cipher', user?.activeCipherTableId ?? 'default'),

              const Divider(color: AppTheme.border),
              const SizedBox(height: 24),

              // How to use
              _SectionHeader('HOW TO USE'),
              const SizedBox(height: 12),
              _HowToStep('1', 'Create a cipher table in the Cipher tab'),
              _HowToStep('2', 'Add your friend by email in the Friends tab'),
              _HowToStep('3', 'Share your cipher table with that friend'),
              _HowToStep(
                  '4', 'Both friends now use the same key to encode & decode'),
              _HowToStep('5',
                  'Send encoded messages via WhatsApp, Telegram, or any app!'),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await auth.signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: Text('SIGN OUT',
                      style: GoogleFonts.spaceMono(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warning,
                    side: const BorderSide(color: AppTheme.warning),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.spaceMono(
                  color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.spaceMono(
                  color: AppTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(text,
            style: GoogleFonts.spaceMono(
                fontSize: 11,
                color: AppTheme.textSecondary,
                letterSpacing: 2)),
      ],
    );
  }
}

class _HowToStep extends StatelessWidget {
  final String num;
  final String text;
  const _HowToStep(this.num, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.accent),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Text(num,
                  style: GoogleFonts.spaceMono(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.spaceMono(
                    color: AppTheme.textSecondary, fontSize: 12, height: 1.6)),
          ),
        ],
      ),
    );
  }
}
