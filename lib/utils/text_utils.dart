const _accentGroups = {
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final Map<int, int> _plainUnits = {
  for (final group in _accentGroups.entries)
    for (final unit in group.value.codeUnits) unit: group.key.codeUnitAt(0),
};

String normalizeText(String input) {
  final buffer = StringBuffer();
  for (final unit in input.toLowerCase().codeUnits) {
    buffer.writeCharCode(_plainUnits[unit] ?? unit);
  }
  return buffer.toString();
}

String previewAround(String content, String query, {int lead = 24}) {
  final flat = content.replaceAll(RegExp(r'\s+'), ' ').trim();
  final key = normalizeText(query.trim());
  if (key.isEmpty) return flat;
  final index = normalizeText(flat).indexOf(key);
  if (index <= lead) return flat;
  final wordStart = flat.lastIndexOf(' ', index - lead) + 1;
  if (wordStart == 0) return flat;
  return '...${flat.substring(wordStart)}';
}

String formatDateTime(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  final date = '${two(value.day)}/${two(value.month)}/${value.year}';
  return '$date ${two(value.hour)}:${two(value.minute)}';
}
