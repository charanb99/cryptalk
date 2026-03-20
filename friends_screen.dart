// lib/screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  final _fs = FirestoreService();
  final _emailCtrl = TextEditingController();
  late TabController _tabs;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _sending = true);
    final user = await _fs.getUserByEmail(email);
    setState(() => _sending = false);

    if (user == null) {
      _snack('User not found', isError: true);
      return;
    }
    await _fs.sendFriendRequest(user.uid);
    _emailCtrl.clear();
    _snack('Friend request sent to ${user.displayName}!');
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.spaceMono()),
        backgroundColor: isError ? AppTheme.warning : AppTheme.card,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareCipher(AppUser friend) async {
    final table = await _fs.getActiveCipherTable();
    if (table == null) {
      _snack('No active cipher table!', isError: true);
      return;
    }
    await _fs.shareCipherWithFriend(friend.uid, table);
    _snack('Cipher shared with ${friend.displayName}!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('FRIENDS'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: GoogleFonts.spaceMono(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'FRIENDS'),
            Tab(text: 'REQUESTS'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Add friend bar
          Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailCtrl,
                    style: GoogleFonts.spaceMono(
                        color: AppTheme.textPrimary, fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Add friend by email...',
                      prefixIcon:
                          Icon(Icons.person_add_outlined, color: AppTheme.accent),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendRequest(),
                  ),
                ),
                const SizedBox(width: 12),
                _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: AppTheme.accent, strokeWidth: 2))
                    : IconButton(
                        onPressed: _sendRequest,
                        icon:
                            const Icon(Icons.send, color: AppTheme.accent, size: 20),
                      ),
              ],
            ),
          ),

          // Tabs content
          Expanded(
            child: StreamBuilder<AppUser>(
              stream: _fs.watchCurrentUser(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: AppTheme.accent));
                }
                final me = snap.data!;
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _FriendsList(
                      uids: me.friendUids,
                      fs: _fs,
                      onShareCipher: _shareCipher,
                      onRemove: (uid) => _fs.removeFriend(uid),
                    ),
                    _RequestsList(
                      uids: me.pendingFriendRequests,
                      fs: _fs,
                      onAccept: (uid) => _fs.acceptFriendRequest(uid),
                      onDecline: (uid) => _fs.declineFriendRequest(uid),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsList extends StatelessWidget {
  final List<String> uids;
  final FirestoreService fs;
  final Future<void> Function(AppUser) onShareCipher;
  final Future<void> Function(String) onRemove;

  const _FriendsList({
    required this.uids,
    required this.fs,
    required this.onShareCipher,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline,
                color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('No friends yet.',
                style:
                    GoogleFonts.spaceMono(color: AppTheme.textSecondary)),
            Text('Add friends by email above.',
                style: GoogleFonts.spaceMono(color: AppTheme.textMuted)),
          ],
        ),
      );
    }

    return FutureBuilder<List<AppUser>>(
      future: fs.getFriends(uids),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }
        final friends = snap.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          separatorBuilder: (_, __) =>
              const Divider(color: AppTheme.border, height: 1),
          itemBuilder: (ctx, i) {
            final f = friends[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined,
                        color: AppTheme.accent, size: 20),
                    tooltip: 'Share my cipher',
                    onPressed: () => onShareCipher(f),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_remove_outlined,
                        color: AppTheme.warning, size: 20),
                    tooltip: 'Remove friend',
                    onPressed: () => onRemove(f.uid),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: (i * 50).ms)
                .slideX(begin: -0.1);
          },
        );
      },
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<String> uids;
  final FirestoreService fs;
  final Future<void> Function(String) onAccept;
  final Future<void> Function(String) onDecline;

  const _RequestsList({
    required this.uids,
    required this.fs,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    if (uids.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread_outlined,
                color: AppTheme.textMuted, size: 48),
            const SizedBox(height: 16),
            Text('No pending requests.',
                style: GoogleFonts.spaceMono(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return FutureBuilder<List<AppUser>>(
      future: fs.getFriends(uids),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snap.data!.length,
          itemBuilder: (ctx, i) {
            final u = snap.data![i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.surface,
                    backgroundImage:
                        u.photoUrl != null ? NetworkImage(u.photoUrl!) : null,
                    child: u.photoUrl == null
                        ? Text(u.displayName[0].toUpperCase(),
                            style: const TextStyle(color: AppTheme.accent))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.displayName,
                            style: GoogleFonts.spaceMono(
                                color: AppTheme.textPrimary, fontSize: 13)),
                        Text(u.email,
                            style: GoogleFonts.spaceMono(
                                color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.warning, size: 20),
                    onPressed: () => onDecline(u.uid),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: AppTheme.accent, size: 20),
                    onPressed: () => onAccept(u.uid),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (i * 80).ms);
          },
        );
      },
    );
  }
}
