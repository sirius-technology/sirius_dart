import 'dart:convert';

import 'package:sirius/sirius.dart';

void logError(String message) {
  print('\x1B[31m[ERROR] $message\x1B[0m'); // 31 = Red Color
}

void logWarning(String message) {
  print('\x1B[33m[WARNING] $message\x1B[0m'); // 33 = Yellow Color
}

void logSuccess(String message) {
  print('\x1B[32m[SUCCESS] $message\x1B[0m'); // 32 = Green Color
}

void throwError(String message) {
  const String red = '\x1B[31m'; // ANSI code for red
  const String reset = '\x1B[0m'; // Reset color

  throw Exception('$red❌ ERROR: $message$reset');
}

void logMap(Map<String, dynamic> map) {
  print("📌 Map Log:");
  map.forEach((key, value) {
    print("  ▶ $key: $value");
  });
}

void logMap2(
    Map<String, Map<String, List<Future<Response> Function(Request request)>>>
        routes) {
  final converted = routes.map((key, value) {
    return MapEntry(
      key,
      value.map((method, handlers) {
        return MapEntry(
          method,
          handlers
              .map((handler) => handler.toString())
              .toList(), // Convert function to string
        );
      }),
    );
  });

  String formatted = JsonEncoder.withIndent('  ').convert(converted);
  print(formatted);
}
