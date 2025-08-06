import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/helpers/logging.dart';

/// A middleware that logs incoming HTTP requests in the console with details such as:
/// - HTTP method
/// - Request path
/// - Response status code
/// - Time taken to process the request
///
/// The log is styled using ANSI escape codes for color, italics, and underline,
/// and is printed using the `logCustom` function.
///
/// Example log output:
/// ```
/// [REQUEST] → GET /api/chefs [200] (12ms)
/// ```
///
/// - HTTP methods are shown in uppercase.
/// - Duration is measured in milliseconds.
/// - The output is color-coded using light cyan (ANSI 96).
///
/// Returns a middleware function that can be used with `app.wrap()` in Sirius.
///
/// Example usage:
/// ```dart
/// app.wrap(loggerHandler());
/// ```
///
/// Returns:
///   A middleware function of type `Future<Response> Function(Request, Future<Response> Function())`
Future<Response> Function(
    Request request, Future<Response> Function() nextHandler) loggerHandler() {
  return (request, nextHandler) async {
    final startTime = DateTime.now();
    final response = await nextHandler();
    final duration = DateTime.now().difference(startTime);

    logCustom(
      'REQUEST',
      '→ ${request.method} ${request.path} '
          '[${response.statusCode}] (${duration.inMilliseconds}ms)',
      colorCode: 96,
      italic: true,
      underline: true,
    );

    return response;
  };
}
