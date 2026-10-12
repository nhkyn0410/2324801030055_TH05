import 'package:flutter/material.dart';

import '../data/note_database.dart';
import '../models/note.dart';
import '../utils/text_utils.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, required this.database, this.note});

  final NoteDatabase database;
  final Note? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleController = TextEditingController(text: widget.note?.title);
  late final _contentController = TextEditingController(
    text: widget.note?.content,
  );
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final note = widget.note;

    if (note == null) {
      await widget.database.insert(
        Note(title: title, content: content, createdAt: now, updatedAt: now),
      );
    } else {
      await widget.database.update(
        note.copyWith(title: title, content: content, updatedAt: now),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = widget.note;

    return Scaffold(
      appBar: AppBar(
        title: Text(note == null ? 'Thêm ghi chú' : 'Chỉnh sửa ghi chú'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        autofocus: note == null,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Tiêu đề'),
                        validator: (value) =>
                            _required(value, 'Vui lòng nhập tiêu đề'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _contentController,
                        textCapitalization: TextCapitalization.sentences,
                        keyboardType: TextInputType.multiline,
                        minLines: 8,
                        maxLines: null,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          alignLabelWithHint: true,
                        ),
                        validator: (value) =>
                            _required(value, 'Vui lòng nhập nội dung'),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Tạo lúc ${formatDateTime(note.createdAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (note.isEdited)
                          Text(
                            'Sửa lần cuối ${formatDateTime(note.updatedAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Lưu'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
