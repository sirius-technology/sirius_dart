import 'package:sirius_backend/sirius_backend.dart';

/// An abstract class representing a middleware wrapper in the Sirius framework.
///
/// A `Wrapper` allows you to intercept and process an incoming HTTP [Request]
/// before it reaches the final route handler, and/or manipulate the resulting [Response].
///
/// You can use wrappers for tasks like:
/// - Authentication / Authorization
/// - Logging
/// - CORS headers
/// - Validation
/// - Error handling
///
/// ### Example:
/// ```dart
/// class AuthWrapper extends Wrapper {
///   @override
///   Future<Response> handle(Request request, Future<Response> Function() nextHandler) async {
///     if (!request.headers.containsKey('Authorization')) {
///       return Response.sendJson({'error': 'Unauthorized'}, statusCode: 401);
///     }
///     return await nextHandler();
///   }
/// }
/// ```
abstract class Wrapper {
  /// Intercepts the [request] before it reaches the route handler and optionally
  /// modifies or short-circuits the flow by returning a [Response] early.
  ///
  /// If processing should continue, it must call [nextHandler] to pass control
  /// to the next wrapper or route handler.
  ///
  /// - [request] → The incoming HTTP request object
  /// - [nextHandler] → A function that proceeds to the next handler or wrapper
  ///
  /// Returns a [Response] object, either directly or from the next handler.
  ///
  /// ### Example use case:
  /// ```dart
  /// return await nextHandler(); // continues to next middleware or route
  /// ```
  Future<Response> handle(
    Request request,
    Future<Response> Function() nextHandler,
  );
}
