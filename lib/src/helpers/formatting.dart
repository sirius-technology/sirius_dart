List<Map<String, dynamic>>? formatStackTrace(StackTrace stackTrace) {
  final lines = stackTrace.toString().split('\n');

  return lines.where((line) => line.trim().isNotEmpty).map((line) {
    final regex = RegExp(r'#\d+\s+(.+?) \((.+?):(\d+)(?::(\d+))?\)');
    final match = regex.firstMatch(line.trim());

    return {
      'function': match?.group(1) ?? 'unknown',
      'file': match?.group(2) ?? 'unknown',
      'line': int.tryParse(match?.group(3) ?? '') ?? -1,
      'column': int.tryParse(match?.group(4) ?? '') ?? -1,
    };
  }).toList();
}
