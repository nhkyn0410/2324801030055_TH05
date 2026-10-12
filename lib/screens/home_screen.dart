import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../data/note_database.dart';
import '../models/note.dart';
import '../utils/text_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.database});

  final NoteDatabase database;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  List<Note> _notes = [];
  int _trashCount = 0;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final notes = await widget.database.activeNotes();
    final trashCount = await widget.database.trashCount();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _trashCount = trashCount;
      _loading = false;
    });
  }

  List<Note> get _visibleNotes {
    final key = normalizeText(_query.trim());
    if (key.isEmpty) return _notes;
    return _notes.where((note) {
      return normalizeText(note.title).contains(key) ||
          normalizeText(note.content).contains(key);
    }).toList();
  }

  void _showMessage(String message, {SnackBarAction? action}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), action: action, persist: false),
      );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  Future<void> _openEditor([Note? note]) async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            NoteEditorScreen(database: widget.database, note: note),
      ),
    );
    if (saved != true) return;
    await _reload();
    if (!mounted) return;
    _showMessage(note == null ? 'Đã thêm ghi chú' : 'Đã cập nhật ghi chú');
  }

  Future<void> _openTrash() async {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => TrashScreen(database: widget.database),
      ),
    );
    await _reload();
  }

  Future<void> _deleteNote(Note note) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Xóa ghi chú?',
      message: 'Ghi chú "${note.title}" sẽ được chuyển vào thùng rác.',
      confirmLabel: 'Xóa',
    );
    if (!confirmed) return;
    await widget.database.moveToTrash(note.id!);
    await _reload();
    if (!mounted) return;
    _showMessage(
      'Đã chuyển vào thùng rác',
      action: SnackBarAction(
        label: 'Hoàn tác',
        onPressed: () async {
          await widget.database.restore(note.id!);
          await _reload();
        },
      ),
    );
  }

  void _showNoteActions(Note note) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formatDateTime(note.createdAt)),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openEditor(note);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text(
                  'Xóa ghi chú',
                  style: TextStyle(color: scheme.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _deleteNote(note);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(List<Note> notes) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notes.isEmpty) {
      return const EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'Chưa có ghi chú nào',
        message: 'Nhấn nút Thêm ghi chú để bắt đầu.',
      );
    }
    if (notes.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Không tìm thấy ghi chú',
        message: 'Hãy thử một từ khóa khác.',
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return SlidableAutoCloseBehavior(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        itemCount: notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = notes[index];
          return ClipRRect(
            key: ValueKey(note.id),
            borderRadius: BorderRadius.circular(16),
            child: Slidable(
              groupTag: 'notes',
              endActionPane: ActionPane(
                motion: const BehindMotion(),
                extentRatio: 0.26,
                children: [
                  SlidableAction(
                    onPressed: (context) => _deleteNote(note),
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    icon: Icons.delete_outline,
                    label: 'Xóa',
                  ),
                ],
              ),
              child: NoteCard(
                note: note,
                query: _query,
                onTap: () => _openEditor(note),
                onLongPress: () => _showNoteActions(note),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = _visibleNotes;
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú'),
        actions: [
          IconButton(
            tooltip: 'Thùng rác',
            onPressed: _openTrash,
            icon: Badge(
              isLabelVisible: _trashCount > 0,
              label: Text('$_trashCount'),
              child: const Icon(Icons.delete_outline),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Tìm kiếm ghi chú',
              elevation: const WidgetStatePropertyAll(0),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 16),
              ),
              leading: const Icon(Icons.search),
              trailing: [
                if (_query.isNotEmpty)
                  IconButton(
                    tooltip: 'Xóa từ khóa',
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.close),
                  ),
              ],
              onChanged: (value) => setState(() => _query = value),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          if (searching && _notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Tìm thấy ${notes.length} ghi chú',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(child: _buildList(notes)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ghi chú'),
      ),
    );
  }
}
