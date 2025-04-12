import 'dart:io';

/// Represents an HTTP response structure used in the Sirius backend framework.
///
/// The `Response` class encapsulates the response data, HTTP status code,
/// and a flag to indicate if the request should proceed to the next handler.
///
/// ### Example
/// ```dart
/// final response = Response.send({"message": "Success"}, status: HttpStatus.ok);
/// return response;
/// ```
class Response {
  /// The actual data to return in the HTTP response.
  dynamic data;

  /// The HTTP status code of the response. Defaults to 200 (OK).
  int statusCode;

  /// A flag that indicates whether the current middleware/controller should pass control to the next.
  ///
  /// If `isNext` is `true`, it means the middleware should call the next handler in the pipeline.
  bool isNext = false;

  dynamic passedData;

  /// Creates a new `Response` object with the given [data] and [statusCode].
  ///
  /// Set [isNext] to true if you want this response to indicate that the next handler should be executed.
  ///
  /// ### Example
  /// ```dart
  /// final customResponse = Response({"result": "done"}, HttpStatus.created);
  /// ```
  Response(
      [this.data,
      this.statusCode = HttpStatus.ok,
      this.isNext = false,
      this.passedData]);

  /// Factory method to create a standard response with optional status code.
  ///
  /// [data] is the response body, and [status] is the HTTP status code (default is 200 OK).
  ///
  /// ### Example
  /// ```dart
  /// return Response.send({"message": "Data saved successfully"}, status: HttpStatus.ok);
  /// ```
  static Response send(dynamic data, {int status = HttpStatus.ok}) {
    return Response(data, status);
  }

  /// Returns a [Response] object that signals the framework to continue
  /// to the next middleware or final handler.
  ///
  /// This is typically used inside middleware when you want to allow
  /// the request to proceed without stopping the processing chain.
  ///
  /// You can optionally pass data using [passData], which will be accessible
  /// to subsequent middleware or handlers via the request context.
  ///
  /// ### Example
  /// ```dart
  /// if (!authenticated) {
  ///   return Response.send({"error": "Unauthorized"}, status: HttpStatus.unauthorized);
  /// }
  ///
  /// // Continue to the next middleware or handler
  /// return Response.next(passData: {"userId": 123});
  /// ```
  static Response next({dynamic passData}) {
    return Response(null, HttpStatus.ok, true, passData);
  }
}
