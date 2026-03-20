// lib/screens/encode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class EncodeScreen extends StatefulWidget {
  const EncodeScreen({super.key});

  @override
  State<EncodeScreen> createState() => _EncodeScreenState();
}

class _EncodeScreenState extends State<EncodeScreen> {
  final _controller = TextEditingController();
  final _fs = FirestoreService();
  CipherTable? _table;
  String _encoded = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTable();
    _controller.addListener(_encode);
  }

  Future<void> _loadTable() async {
    final t = await _fs.getActiveCipherTable();
    setState(() {
      _table = t ?? CipherTable.defaultTable();
      _loading = false;
      _encode();
    });
  }

  void _encode() {
    if (_table == null) return;
    setState(() {
      _encoded = _table!.encode(_controller.text);
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _encoded));
    ScaffoldMessenger.of(context).showSnackBar(
      _snack('Encoded message copied!'),
    );
  }

  void _share() {
    if (_encoded.isNotEmpty) {
      Share.share(_encoded, subject: 'Secret message from CryptTalk');
    }
  }

  SnackBar _snack(String msg) => SnackBar(
        content: Text(msg, style: GoogleFonts.spaceMono()),
        backgroundColor: AppTheme.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: AppTheme.accent)),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('ENCODE'),
        actions: [
          if (_table != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text(
                  _table!.name,
                  style: GoogleFonts.spaceMono(
                      fontSize: 10, color: AppTheme.accent),
                ),
                backgroundColor: AppTheme.accentDim,
                side: const BorderSide(color: AppTheme.accent),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('PLAINTEXT'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    style: GoogleFonts.spaceMono(
                        color: AppTheme.textPrimary, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Type your secret message here...',
                    ),
                  ),

                  const SizedBox(height: 24),
                  _SectionLabel('ENCODED OUTPUT'),
                  const SizedBox(height: 8),

                  // Encoded output box
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        border: Border.all(
                          color: _encoded.isNotEmpty
                              ? AppTheme.accent
                              : AppTheme.border,
                        ),
                        boxShadow: _encoded.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentGlow,
                                  blurRadius: 16,
                                )
                              ]
                            : null,
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _encoded.isEmpty
                              ? 'Encoded message will appear here...'
                              : _encoded,
                          style: GoogleFonts.spaceMono(
                            color: _encoded.isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.accent,
                            fontSize: 18,
                            height: 1.8,
                          ),
                        ).animate(key: ValueKey(_encoded)).fadeIn(duration: 200.ms),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _encoded.isEmpty ? null : _copyToClipboard,
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text('COPY',
                              style: GoogleFonts.spaceMono(
                                  fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accent,
                            side: const BorderSide(color: AppTheme.accent),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _encoded.isEmpty ? null : _share,
                          icon: const Icon(Icons.share, size: 18),
                          label: Text('SHARE',
                              style: GoogleFonts.spaceMono(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

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
