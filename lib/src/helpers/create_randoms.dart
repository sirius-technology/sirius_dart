import 'dart:math';

String createUuid() {
  final random = Random();
  const chars = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';
  return chars.replaceAllMapped(RegExp('[xy]'), (match) {
    final r = random.nextInt(16); // Random number between 0 and 15
    final v = match.group(0) == 'x'
        ? r
        : (r & 0x3 | 0x8); // For 'x', use r; for 'y', ensure 8, 9, a, or b
    return v.toRadixString(16);
  });
}
