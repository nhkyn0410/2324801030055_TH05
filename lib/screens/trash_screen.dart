import 'package:flutter/material.dart';

import '../data/note_database.dart';
import '../models/note.dart';
import '../utils/text_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key, required this.database});

  final NoteDatabase database;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final notes = await widget.database.trashedNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _restore(Note note) async {
    await widget.database.restore(note.id!);
    await _reload();
    if (!mounted) return;
    _showMessage('Đã khôi phục ghi chú');
  }

  Future<void> _deleteForever(Note note) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xóa vĩnh viễn?',
      message: 'Ghi chú "${note.title}" sẽ bị xóa và không thể khôi phục.',
      confirmLabel: 'Xóa vĩnh viễn',
    );
    if (!confirmed) return;
    await widget.database.deleteForever(note.id!);
    await _reload();
    if (!mounted) return;
    _showMessage('Đã xóa vĩnh viễn');
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Dọn sạch thùng rác?',
      message:
          'Tất cả ${_notes.length} ghi chú trong thùng rác sẽ bị xóa vĩnh viễn.',
      confirmLabel: 'Dọn sạch',
    );
    if (!confirmed) return;
    await widget.database.emptyTrash();
    await _reload();
    if (!mounted) return;
    _showMessage('Đã dọn sạch thùng rác');
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      return const EmptyState(
        icon: Icons.delete_outline,
        title: 'Thùng rác trống',
        message: 'Ghi chú đã xóa sẽ xuất hiện ở đây để bạn khôi phục.',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = _notes[index];
        return ClipRRect(
          key: ValueKey(note.id),
          borderRadius: BorderRadius.circular(16),
          child: NoteCard(
            note: note,
            timeLabel: 'Đã xóa lúc ${formatDateTime(note.deletedAt!)}',
            actions: [
              TextButton.icon(
                onPressed: () => _restore(note),
                icon: const Icon(Icons.restore),
                label: const Text('Khôi phục'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: scheme.error),
                onPressed: () => _deleteForever(note),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Xóa vĩnh viễn'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thùng rác'),
        actions: [
          if (_notes.isNotEmpty)
            IconButton(
              tooltip: 'Dọn sạch thùng rác',
              onPressed: _emptyTrash,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }
}
