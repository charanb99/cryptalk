// lib/screens/cipher_table_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class CipherTableScreen extends StatefulWidget {
  const CipherTableScreen({super.key});

  @override
  State<CipherTableScreen> createState() => _CipherTableScreenState();
}

class _CipherTableScreenState extends State<CipherTableScreen> {
  final _fs = FirestoreService();
  final _uuid = const Uuid();
  List<CipherTable> _tables = [];
  String? _activeId;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadActive();
  }

  Future<void> _loadActive() async {
    final t = await _fs.getActiveCipherTable();
    if (mounted) setState(() => _activeId = t?.id);
  }

  void _editTable(CipherTable table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CipherEditorScreen(
          table: table,
          onSave: (updated) async {
            await _fs.saveCipherTable(updated);
          },
        ),
      ),
    );
  }

  void _createNew() {
    final table = CipherTable(
      id: _uuid.v4(),
      name: 'New Cipher ${_tables.length + 1}',
      createdAt: DateTime.now(),
      table: {...CipherTable.defaultTable().table},
    );
    _editTable(table);
  }

  Future<void> _generateWithAI() async {
    setState(() => _aiLoading = true);
    final suggested = await AiService.suggestCipherTable();
    setState(() => _aiLoading = false);

    if (suggested.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('AI unavailable. Add your API key in ai_service.dart.',
                    style: GoogleFonts.spaceMono()),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
      return;
    }

    final table = CipherTable(
      id: _uuid.v4(),
      name: 'AI Cipher ${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      table: suggested,
    );
    _editTable(table);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('CIPHER TABLES'),
        actions: [
          IconButton(
            icon: _aiLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            tooltip: 'Generate with AI',
            onPressed: _aiLoading ? null : _generateWithAI,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNew,
        backgroundColor: AppTheme.accent,
        child: const Icon(Icons.add, color: AppTheme.bg),
      ),
      body: StreamBuilder<List<CipherTable>>(
        stream: _fs.watchCipherTables(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent));
          }
          _tables = snap.data ?? [];
          if (_tables.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.table_chart_outlined,
                      color: AppTheme.textMuted, size: 48),
                  const SizedBox(height: 16),
                  Text('No cipher tables yet.',
                      style: GoogleFonts.spaceMono(
                          color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Tap + to create one.',
                      style: GoogleFonts.spaceMono(color: AppTheme.textMuted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _tables.length,
            separatorBuilder: (_, __) => const Divider(color: AppTheme.border),
            itemBuilder: (ctx, i) {
              final t = _tables[i];
              final isActive = t.id == _activeId;
              return _CipherCard(
                table: t,
                isActive: isActive,
                onActivate: () async {
                  await _fs.setActiveCipherTable(t.id);
                  setState(() => _activeId = t.id);
                },
                onEdit: () => _editTable(t),
                onDelete: () async {
                  await _fs.deleteCipherTable(t.id);
                },
              ).animate().fadeIn(delay: (i * 60).ms).slideX(begin: -0.1);
            },
          );
        },
      ),
    );
  }
}

class _CipherCard extends StatelessWidget {
  final CipherTable table;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CipherCard({
    required this.table,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(
          color: isActive ? AppTheme.accent : AppTheme.border,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: AppTheme.accentGlow, blurRadius: 12)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim,
                    border: Border.all(color: AppTheme.accent),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text('ACTIVE',
                      style: GoogleFonts.spaceMono(
                          fontSize: 10,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: Text(
                  table.name,
                  style: GoogleFonts.spaceMono(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                color: AppTheme.surface,
                icon: const Icon(Icons.more_vert,
                    color: AppTheme.textSecondary, size: 20),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                  if (v == 'activate') onActivate();
                },
                itemBuilder: (_) => [
                  if (!isActive)
                    PopupMenuItem(
                      value: 'activate',
                      child: Text('Set as Active',
                          style: GoogleFonts.spaceMono(
                              color: AppTheme.accent, fontSize: 13)),
                    ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit',
                        style: GoogleFonts.spaceMono(
                            color: AppTheme.textPrimary, fontSize: 13)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: GoogleFonts.spaceMono(
                            color: AppTheme.warning, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Preview first 8 symbols
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: table.table.entries.take(8).map((e) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  '${e.key}→${e.value.first}',
                  style: GoogleFonts.spaceMono(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── Editor ──────────────────────────────────────────────────────────────────

class _CipherEditorScreen extends StatefulWidget {
  final CipherTable table;
  final Future<void> Function(CipherTable) onSave;

  const _CipherEditorScreen({required this.table, required this.onSave});

  @override
  State<_CipherEditorScreen> createState() => _CipherEditorScreenState();
}

class _CipherEditorScreenState extends State<_CipherEditorScreen> {
  late Map<String, List<String>> _tableData;
  late TextEditingController _nameCtrl;
  bool _saving = false;

  static const _letters = 'abcdefghijklmnopqrstuvwxyz ';

  @override
  void initState() {
    super.initState();
    _tableData = Map.from(
      widget.table.table.map((k, v) => MapEntry(k, List<String>.from(v))),
    );
    // Ensure all letters present
    for (final ch in _letters.split('')) {
      _tableData.putIfAbsent(ch, () => [ch]);
    }
    _nameCtrl = TextEditingController(text: widget.table.name);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final updated = widget.table.copyWith(
      table: _tableData,
      name: _nameCtrl.text.trim().isEmpty ? widget.table.name : _nameCtrl.text.trim(),
    );
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  void _editEntry(String letter) {
    final ctrl = TextEditingController(
        text: (_tableData[letter] ?? []).join(', '));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          'Substitutes for "$letter"',
          style: GoogleFonts.spaceMono(color: AppTheme.accent, fontSize: 14),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: GoogleFonts.spaceMono(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: '@, △, 🔴 (comma separated)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: GoogleFonts.spaceMono(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final subs = ctrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              setState(() => _tableData[letter] = subs.isEmpty ? [letter] : subs);
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('EDIT CIPHER'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 2),
                  ))
              : IconButton(
                  icon: const Icon(Icons.check, color: AppTheme.accent),
                  onPressed: _save,
                ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _nameCtrl,
              style: GoogleFonts.spaceMono(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Cipher Name'),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _letters.length,
              itemBuilder: (ctx, i) {
                final letter = _letters[i];
                final subs = _tableData[letter] ?? [letter];
                return GestureDetector(
                  onTap: () => _editEntry(letter),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          letter == ' ' ? '⎵' : letter.toUpperCase(),
                          style: GoogleFonts.spaceMono(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          subs.take(2).join(' '),
                          style: GoogleFonts.spaceMono(
                            color: AppTheme.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
