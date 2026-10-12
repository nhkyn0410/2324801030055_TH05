import 'package:flutter/material.dart';

import '../models/note.dart';
import '../utils/text_utils.dart';
import 'highlighted_text.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    this.query = '',
    this.timeLabel,
    this.actions = const [],
    this.onTap,
    this.onLongPress,
  });

  final Note note;
  final String query;
  final String? timeLabel;
  final List<Widget> actions;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, actions.isEmpty ? 16 : 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HighlightedText(
                text: note.title,
                query: query,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              HighlightedText(
                text: previewAround(note.content, query),
                query: query,
                maxLines: 2,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: scheme.outline),
                  const SizedBox(width: 6),
                  Text(
                    timeLabel ?? formatDateTime(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
                ],
              ),
              if (actions.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(spacing: 4, children: actions),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
