import 'package:sirius_backend/sirius_backend.dart';

/// Abstract class representing a middleware component in the Sirius framework.
///
/// Middleware allows you to intercept and process HTTP requests before they
/// reach the final route handler. You can use middleware to implement
/// authentication, logging, input transformation, rate limiting, and more.
///
/// To create a custom middleware, extend this class and override the [handle] method.
///
/// ### Example: Logging Middleware
/// ```dart
/// class LoggingMiddleware extends Middleware {
///   @override
///   Future<Response> handle(Request request) async {
///     print('Incoming ${request.method} request to ${request.httpRequest.uri}');
///     return Response.next(); // Continue to the next middleware or route
///   }
/// }
/// ```
///
/// ### Example: Auth Middleware
/// ```dart
/// class AuthMiddleware extends Middleware {
///   @override
///   Future<Response> handle(Request request) async {
///     final token = request.headerValue('authorization');
///     if (token == 'valid_token') {
///       return Response.next();
///     }
///     return Response.send({'error': 'Unauthorized'}, status: 401);
///   }
/// }
/// ```
///
/// Middleware is executed in the order it is registered for a given route or globally.
abstract class Middleware {
  /// Processes the incoming [request] and returns a [Response].
  ///
  /// If the middleware should allow the request to continue to the next
  /// middleware or handler, return `Response.next()`.
  ///
  /// If the middleware wants to stop the flow and return a response immediately,
  /// return `Response.send(...)`.
  Future<Response> handle(Request request);
}
