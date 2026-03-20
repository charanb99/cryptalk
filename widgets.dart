// lib/widgets/widgets.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

// ─── Section Label ────────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: AppTheme.accent),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.spaceMono(
            fontSize: 11,
            color: AppTheme.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

// ─── Glowing Box ─────────────────────────────────────────────────────────────
class GlowBox extends StatelessWidget {
  final Widget child;
  final bool active;
  final EdgeInsetsGeometry? padding;

  const GlowBox({
    super.key,
    required this.child,
    this.active = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: active ? AppTheme.accent : AppTheme.border,
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [BoxShadow(color: AppTheme.accentGlow, blurRadius: 20)]
            : [],
      ),
      child: child,
    );
  }
}

// ─── Active Badge ─────────────────────────────────────────────────────────────
class ActiveBadge extends StatelessWidget {
  const ActiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentDim,
        border: Border.all(color: AppTheme.accent),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        'ACTIVE',
        style: GoogleFonts.spaceMono(
          fontSize: 9,
          color: AppTheme.accent,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ─── Cipher Preview Chip ──────────────────────────────────────────────────────
class CipherChip extends StatelessWidget {
  final String letter;
  final String symbol;

  const CipherChip({super.key, required this.letter, required this.symbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: letter,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            TextSpan(
              text: '→',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppTheme.textMuted,
              ),
            ),
            TextSpan(
              text: symbol,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Snackbar ─────────────────────────────────────────────────────────
void showCryptSnack(BuildContext context, String message,
    {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: GoogleFonts.spaceMono(
          color: isError ? AppTheme.warning : AppTheme.accent,
          fontSize: 12,
        ),
      ),
      backgroundColor: AppTheme.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(
            color: isError ? AppTheme.warning : AppTheme.accent),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

// ─── Empty State ─────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.spaceMono(
                color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.spaceMono(
                color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────
class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.accent),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: GoogleFonts.spaceMono(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
