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

/// Logs a custom-styled message with ANSI colors and text effects.
///
/// Parameters:
/// - [label]        → Tag or prefix (e.g. INFO, ERROR)
/// - [message]      → The message to log
/// - [colorCode]    → ANSI foreground color code (default: 37 = white)
/// - [bgColorCode]  → Optional background color code (e.g. 41 = red background)
/// - [bold]         → If true, makes the text bold
/// - [italic]       → If true, makes the text italic (not all terminals support)
/// - [underline]    → If true, underlines the text
///
/// ---
///
/// ### 🎨 ANSI Color Codes
///
/// #### Foreground (Text) Colors
/// | Color Name | Code | Description        |
/// |------------|------|--------------------|
/// | Black      | 30   | Standard Black     |
/// | Red        | 31   | Standard Red       |
/// | Green      | 32   | Standard Green     |
/// | Yellow     | 33   | Standard Yellow    |
/// | Blue       | 34   | Standard Blue      |
/// | Magenta    | 35   | Standard Magenta   |
/// | Cyan       | 36   | Standard Cyan      |
/// | White      | 37   | Standard White     |
///
/// #### Bright (Light) Foreground Colors
/// | Color Name     | Code |
/// |----------------|------|
/// | Bright Black   | 90   |
/// | Bright Red     | 91   |
/// | Bright Green   | 92   |
/// | Bright Yellow  | 93   |
/// | Bright Blue    | 94   |
/// | Bright Magenta | 95   |
/// | Bright Cyan    | 96   |
/// | Bright White   | 97   |
///
/// #### Background Colors
/// | Color Name         | Code |
/// |--------------------|------|
/// | Background Black   | 40   |
/// | Background Red     | 41   |
/// | Background Green   | 42   |
/// | Background Yellow  | 43   |
/// | Background Blue    | 44   |
/// | Background Magenta | 45   |
/// | Background Cyan    | 46   |
/// | Background White   | 47   |
///
/// #### Bright Background Colors
/// | Color Name                | Code |
/// |---------------------------|------|
/// | Bright Background Black   | 100  |
/// | Bright Background Red     | 101  |
/// | Bright Background Green   | 102  |
/// | Bright Background Yellow  | 103  |
/// | Bright Background Blue    | 104  |
/// | Bright Background Magenta | 105  |
/// | Bright Background Cyan    | 106  |
/// | Bright Background White   | 107  |
///
/// #### Text Styles
/// | Style         | Code |
/// |---------------|------|
/// | Reset         | 0    |
/// | Bold          | 1    |
/// | Dim           | 2    |
/// | Italic        | 3    |
/// | Underline     | 4    |
/// | Blink         | 5    |
/// | Invert        | 7    |
/// | Hidden        | 8    |
/// | Strikethrough | 9    |

void logCustom(
  String label,
  String message, {
  int colorCode = 37,
  int? bgColorCode,
  bool bold = false,
  bool italic = false,
  bool underline = false,
}) {
  final buffer = StringBuffer('\x1B[');

  final styles = <String>[];

  if (bold) styles.add('1');
  if (italic) styles.add('3');
  if (underline) styles.add('4');

  styles.add('$colorCode'); // Foreground color

  if (bgColorCode != null) {
    styles.add('$bgColorCode'); // Background color
  }

  buffer.write(styles.join(';'));
  buffer.write('m');

  // Final print
  buffer.write('[$label] $message');
  buffer.write('\x1B[0m'); // Reset all styles

  print(buffer.toString());
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
