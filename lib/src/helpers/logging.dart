import 'dart:convert';

import 'package:sirius_backend/sirius_backend.dart';

void logError(String message) {
  print('\x1B[31m[ERROR] $message\x1B[0m'); // 31 = Red Color
}

void logWarning(String message) {
  print('\x1B[33m[WARNING] $message\x1B[0m'); // 33 = Yellow Color
}

void logSuccess(String message) {
  print('\x1B[32m[SUCCESS] $message\x1B[0m'); // 32 = Green Color
}

void logMap(Map<String, dynamic> map) {
  print("📌 Map Log:");
  map.forEach((key, value) {
    print("  ▶ $key: $value");
  });
}

void logMap2(
    Map<
            String,
            Map<
                String,
                (
                  List<
                      Future<Response> Function(Request request,
                          Future<Response> Function() nextHandler)>,
                  List<Future<Response> Function(Request request)>
                )>>
        routes) {
  final converted = routes.map((path, methodsMap) {
    return MapEntry(
      path,
      methodsMap.map((method, handlerTuple) {
        final wrapperList = handlerTuple.$1.map((f) => f.toString()).toList();
        final handlerList = handlerTuple.$2.map((f) => f.toString()).toList();

        return MapEntry(
          method,
          {
            "wrappers": wrapperList,
            "handlers": handlerList,
          },
        );
      }),
    );
  });

  String formatted = JsonEncoder.withIndent('  ').convert(converted);
  print(formatted);
}
