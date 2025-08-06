import 'dart:io';

/// Represents an HTTP response structure used in the Sirius backend framework.
///
/// This class encapsulates all the necessary details to construct an HTTP response,
/// including response body, status code, headers, and advanced options like
/// controlling middleware flow and passing contextual data.
///
/// ### Basic Example:
/// ```dart
/// return Response.send({"message": "OK"});
/// ```
///
/// ### Example with StatusCode and Headers:
/// ```dart
/// return Response.send(
///   {"error": "Not Found"},
///   statusCode: HttpStatus.notFound,
///   headers: {"X-Custom-Header": "value"},
/// );
/// ```
class Response {
  /// The response body data. Typically a `Map`, `List`, `String`, or `null`.
  dynamic data;

  /// The HTTP status code of the response.
  /// Defaults to [HttpStatus.ok] (200).
  int statusCode;

  /// Custom headers to include in the HTTP response.
  ///
  /// This allows developers to specify metadata such as:
  /// - `"Content-Type": "application/json"`
  /// - `"X-Powered-By": "Sirius"`
  ///
  /// Example:
  /// ```dart
  /// {
  ///   "Content-Type": "application/json",
  ///   "Cache-Control": "no-cache"
  /// }
  /// ```
  Map<String, dynamic> headers = {};

  /// Internal data store for passing contextual metadata through the response.
  ///
  /// This is useful for passing additional data between middleware layers or handlers,
  /// without sending it in the actual HTTP response body.
  dynamic _contextData;

  /// Retrieves the internal context data passed during processing.
  dynamic get getContextData => _contextData;

  /// Sets extra internal context data to this response.
  ///
  /// Example:
  /// ```dart
  /// response.setContextData = {'user': currentUser};
  /// ```
  set setContextData(dynamic data) {
    _contextData = data;
  }

  /// A callback to override or manipulate low-level response headers.
  ///
  /// This provides access to the raw [HttpHeaders] object for setting advanced options
  /// such as CORS headers, cookies, security flags, etc.
  ///
  /// ### Example:
  /// ```dart
  /// overrideHeaders: (headers) {
  ///   headers.set('Access-Control-Allow-Origin', '*');
  ///   headers.set('Set-Cookie', 'session=abc123; HttpOnly');
  /// }
  /// ```
  void Function(HttpHeaders headers)? overrideHeaders;

  /// Constructs a [Response] instance.
  ///
  /// - [data]: response body
  /// - [statusCode]: HTTP status code (default is 200 OK)
  /// - [headers]: additional response headers
  /// - [overrideHeaders]: callback for raw header manipulation
  ///
  /// ### Example:
  /// ```dart
  /// final response = Response(
  ///   {"status": "created"},
  ///   HttpStatus.created,
  ///   {"X-App-Version": "1.0"},
  /// );
  /// ```
  Response([
    this.data,
    this.statusCode = HttpStatus.ok,
    this.headers = const {},
    this.overrideHeaders,
  ]);

  /// Creates a standard response with optional status code and headers.
  ///
  /// Recommended for most controller responses.
  ///
  /// ### Example:
  /// ```dart
  /// return Response.send({"message": "Data saved"});
  /// ```
  static Response send(
    dynamic data, {
    int statusCode = HttpStatus.ok,
    Map<String, String>? headers,
    void Function(HttpHeaders headers)? overrideHeaders,
  }) {
    return Response(
      data,
      statusCode,
      headers ?? {},
      overrideHeaders,
    );
  }

  /// Sends a JSON response with appropriate `Content-Type` header.
  ///
  /// Automatically sets `Content-Type: application/json` and accepts any serializable
  /// Dart object (like Map or List) as the response body.
  ///
  /// ### Example:
  /// ```dart
  /// return Response.sendJson({"message": "Success"});
  /// ```
  ///
  /// ### Example with custom statusCode and headers:
  /// ```dart
  /// return Response.sendJson(
  ///   {"error": "Unauthorized"},
  ///   statusCode: HttpStatus.unauthorized,
  ///   headers: {"X-Trace-Id": "abc123"},
  /// );
  /// ```
  static Response sendJson(
    dynamic data, {
    int statusCode = HttpStatus.ok,
    Map<String, String>? headers,
    void Function(HttpHeaders headers)? overrideHeaders,
  }) {
    return Response(
      data,
      statusCode,
      {"Content-Type": "application/json", ...?headers},
      overrideHeaders,
    );
  }

  /// Adds a custom header to the response.
  ///
  /// This can be used to dynamically insert a header key-value pair,
  /// such as `X-Custom-Header`, `Authorization`, etc.
  ///
  /// If the key already exists, it will be overwritten.
  ///
  /// ### Example:
  /// ```dart
  /// final response = Response.send({"message": "Success"});
  /// response.addHeader("X-Powered-By", "Sirius");
  /// return response;
  /// ```
  void addHeader(String key, String value) {
    headers[key] = value;
  }
}
