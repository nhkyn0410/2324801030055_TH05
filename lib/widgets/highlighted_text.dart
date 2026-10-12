import 'package:flutter/material.dart';

import '../utils/text_utils.dart';

class HighlightedText extends StatelessWidget {
  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.maxLines,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final key = normalizeText(query.trim());
    final source = normalizeText(text);
    final spans = <TextSpan>[];

    if (key.isNotEmpty && source.length == text.length) {
      final highlight = TextStyle(
        backgroundColor: scheme.tertiaryContainer,
        color: scheme.onTertiaryContainer,
        fontWeight: FontWeight.w700,
      );
      var start = 0;
      var index = source.indexOf(key);
      while (index >= 0) {
        final end = index + key.length;
        spans.add(TextSpan(text: text.substring(start, index)));
        spans.add(TextSpan(text: text.substring(index, end), style: highlight));
        start = end;
        index = source.indexOf(key, start);
      }
      spans.add(TextSpan(text: text.substring(start)));
    } else {
      spans.add(TextSpan(text: text));
    }

    return Text.rich(
      TextSpan(children: spans),
      style: style,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
