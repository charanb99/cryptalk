// lib/screens/decode_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class DecodeScreen extends StatefulWidget {
  const DecodeScreen({super.key});

  @override
  State<DecodeScreen> createState() => _DecodeScreenState();
}

class _DecodeScreenState extends State<DecodeScreen> {
  final _controller = TextEditingController();
  final _fs = FirestoreService();

  CipherTable? _myTable;
  List<AppUser> _friends = [];
  AppUser? _selectedFriend;
  CipherTable? _friendTable;

  String _decoded = '';
  bool _loading = true;
  bool _decodeMode = 'mine' == 'mine'; // toggle: mine vs friend's cipher
  bool _myMode = true;

  @override
  void initState() {
    super.initState();
    _init();
    _controller.addListener(_decode);
  }

  Future<void> _init() async {
    final t = await _fs.getActiveCipherTable();
    // Get my friends
    // (simplified: we'll load friend list)
    setState(() {
      _myTable = t ?? CipherTable.defaultTable();
      _loading = false;
    });
  }

  Future<void> _selectFriend() async {
    // Show friend picker dialog
    // Load friends
    final userStream = _fs.watchCurrentUser();
    userStream.first.then((user) async {
      final friends = await _fs.getFriends(user.friendUids);
      if (!mounted) return;
      final chosen = await showDialog<AppUser>(
        context: context,
        builder: (ctx) => _FriendPickerDialog(friends: friends),
      );
      if (chosen != null) {
        final sharedCipher = await _fs.getSharedCipher(chosen.uid);
        setState(() {
          _selectedFriend = chosen;
          _friendTable = sharedCipher;
          _myMode = false;
          _decode();
        });
      }
    });
  }

  void _decode() {
    final table = _myMode ? _myTable : _friendTable;
    if (table == null) {
      setState(() => _decoded = '');
      return;
    }
    setState(() {
      _decoded = table.decode(_controller.text);
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _controller.text = data!.text!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('DECODE')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mode toggle
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        _ModeTab(
                          label: 'MY CIPHER',
                          active: _myMode,
                          onTap: () => setState(() {
                            _myMode = true;
                            _decode();
                          }),
                        ),
                        _ModeTab(
                          label: "FRIEND'S CIPHER",
                          active: !_myMode,
                          onTap: () {
                            if (_selectedFriend == null) {
                              _selectFriend();
                            } else {
                              setState(() {
                                _myMode = false;
                                _decode();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  if (!_myMode && _selectedFriend != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline,
                              color: AppTheme.accent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _selectedFriend!.displayName,
                            style: GoogleFonts.spaceMono(
                                color: AppTheme.accent, fontSize: 12),
                          ),
                          const Spacer(),
                          if (_friendTable == null)
                            Text(
                              'No shared cipher',
                              style: GoogleFonts.spaceMono(
                                  color: AppTheme.warning, fontSize: 11),
                            ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _selectFriend,
                            child: const Icon(Icons.swap_horiz,
                                color: AppTheme.textSecondary, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Input
                  Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      TextButton.icon(
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.paste,
                            size: 14, color: AppTheme.textSecondary),
                        label: Text('PASTE',
                            style: GoogleFonts.spaceMono(
                                fontSize: 11, color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    style: GoogleFonts.spaceMono(
                        color: AppTheme.warning, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Paste encoded message here...',
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Container(width: 3, height: 14, color: AppTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        'DECODED',
                        style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                            letterSpacing: 2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        border: Border.all(
                          color: _decoded.isNotEmpty
                              ? AppTheme.accent
                              : AppTheme.border,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _decoded.isEmpty
                              ? 'Decoded message will appear here...'
                              : _decoded,
                          style: GoogleFonts.spaceMono(
                            color: _decoded.isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.textPrimary,
                            fontSize: 18,
                            height: 1.6,
                          ),
                        ).animate(key: ValueKey(_decoded)).fadeIn(duration: 200.ms),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _decoded.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _decoded));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Decoded text copied!',
                                      style: GoogleFonts.spaceMono()),
                                  backgroundColor: AppTheme.card,
                                ),
                              );
                            },
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text('COPY DECODED',
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
                ],
              ),
            ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? AppTheme.bg : AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendPickerDialog extends StatelessWidget {
  final List<AppUser> friends;
  const _FriendPickerDialog({required this.friends});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SELECT FRIEND',
                style: GoogleFonts.spaceMono(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            if (friends.isEmpty)
              Text('No mutual friends yet.',
                  style: GoogleFonts.spaceMono(color: AppTheme.textSecondary))
            else
              ...friends.map((f) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.card,
                      backgroundImage:
                          f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
                      child: f.photoUrl == null
                          ? Text(f.displayName[0].toUpperCase(),
                              style: const TextStyle(color: AppTheme.accent))
                          : null,
                    ),
                    title: Text(f.displayName,
                        style: GoogleFonts.spaceMono(
                            color: AppTheme.textPrimary, fontSize: 13)),
                    subtitle: Text(f.email,
                        style: GoogleFonts.spaceMono(
                            color: AppTheme.textMuted, fontSize: 11)),
                    onTap: () => Navigator.pop(context, f),
                  )),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CANCEL',
                  style: GoogleFonts.spaceMono(color: AppTheme.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
