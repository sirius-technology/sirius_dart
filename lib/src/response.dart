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
  /// The response body data. Can be any type (usually a Map or String).
  dynamic data;

  /// The HTTP status code of the response.
  /// Defaults to [HttpStatus.ok] (200).
  int statusCode;

  /// Custom headers to include in the HTTP response.
  ///
  /// Developers can pass additional metadata such as:
  /// `"Content-Type": "application/json"`.
  Map<String, dynamic> headers = {};

  /// A callback to override default headers using [HttpHeaders].
  ///
  /// Useful for setting advanced headers (e.g., CORS, cookies, custom control).
  ///
  /// ### Example:
  /// ```dart
  /// overrideHeaders: (headers) {
  ///   headers.set('Access-Control-Allow-Origin', '*');
  /// }
  /// ```
  void Function(HttpHeaders headers)? overrideHeaders;

  /// Indicates whether this response should proceed to the next handler or middleware.
  ///
  /// If `true`, the framework continues processing with the next layer.
  bool isNext = false;

  /// Used to pass data from middleware to downstream handlers or controllers.
  ///
  /// Access this via `request.receiveData`.
  dynamic passedData;

  /// Constructs a [Response] instance with optional data, statusCode, headers,
  /// override logic, continuation flag, and passed data.
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
    this.isNext = false,
    this.passedData,
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

  /// Signals the framework to continue request handling to the next handler.
  ///
  /// Mostly used in middleware chains when a request passes validation or authentication.
  ///
  /// You can optionally pass context using [passData], which can be retrieved
  /// in the next handler or controller via `request.receiveData`.
  ///
  /// ### Example:
  /// ```dart
  /// if (isAuthenticated) {
  ///   return Response.next(passData: {"userId": 123});
  /// }
  ///
  /// return Response.send({"error": "Unauthorized"}, statusCode: HttpStatus.unauthorized);
  /// ```
  static Response next({dynamic passData}) {
    return Response(null, HttpStatus.ok, {}, null, true, passData);
  }
}
