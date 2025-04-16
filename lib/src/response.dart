import 'dart:io';

/// Represents an HTTP response structure used in the Sirius backend framework.
///
/// The `Response` class encapsulates response data, status code, headers,
/// a signal to continue to the next handler (middleware or controller),
/// and the ability to pass data between layers.
///
/// ### Example: Basic usage
/// ```dart
/// return Response.send({"message": "OK"});
/// ```
///
/// ### Example: Custom status and headers
/// ```dart
/// return Response.send(
///   {"error": "Not Found"},
///   status: HttpStatus.notFound,
///   headers: {"X-Custom-Header": "value"},
/// );
/// ```
class Response {
  /// The body data of the response (e.g., a message, JSON, etc.)
  dynamic data;

  /// The HTTP status code to send with the response.
  /// Defaults to [HttpStatus.ok] (200).
  int statusCode;

  /// HTTP headers to send with the response.
  /// Defaults to an empty map.
  HttpHeaders? headers;

  /// A flag indicating whether to continue to the next handler.
  ///
  /// If `true`, the request will be forwarded to the next middleware or route handler.
  bool isNext = false;

  /// Optional data to pass from middleware to the next handler or controller.
  dynamic passedData;

  /// Constructs a `Response` instance.
  ///
  /// [data] is the response body.
  /// [statusCode] is the HTTP status (default is 200).
  /// [headers] are additional response headers.
  /// [isNext] determines whether to continue the request chain.
  /// [passedData] allows passing context between layers.
  ///
  /// ### Example
  /// ```dart
  /// final response = Response(
  ///   {"status": "created"},
  ///   HttpStatus.created,
  ///   {"X-App-Version": "1.0"},
  /// );
  /// ```
  Response(
      [this.data,
      this.statusCode = HttpStatus.ok,
      this.headers,
      this.isNext = false,
      this.passedData]);

  /// Creates a new [Response] with optional [status] and [headers].
  ///
  /// This is the most commonly used method to send responses from controllers.
  ///
  /// ### Example
  /// ```dart
  /// return Response.send({"message": "Welcome!"});
  /// ```
  static Response send(dynamic data,
      {int status = HttpStatus.ok, HttpHeaders? headers}) {
    return Response(data, status, headers);
  }

  /// Creates a `Response` indicating the request should continue to the next handler.
  ///
  /// Typically used in middleware pipelines where some conditions are checked,
  /// and you want the request to be passed forward instead of stopped.
  ///
  /// You can pass optional [passData] to share data with downstream handlers.
  ///
  /// ### Example
  /// ```dart
  /// if (!userIsAuthenticated) {
  ///   return Response.send({"error": "Unauthorized"}, status: HttpStatus.unauthorized);
  /// }
  ///
  /// return Response.next(passData: {"userId": user.id});
  /// ```
  static Response next({dynamic passData}) {
    return Response(null, HttpStatus.ok, null, true, passData);
  }
}
