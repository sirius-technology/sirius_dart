import 'dart:math';

String createUuid() {
  final random = Random.secure();
  const template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx';

  return template.replaceAllMapped(RegExp('[xy]'), (match) {
    final r = random.nextInt(16);
    final v = match.group(0) == 'x' ? r : (r & 0x3 | 0x8);
    return v.toRadixString(16);
  });
}
