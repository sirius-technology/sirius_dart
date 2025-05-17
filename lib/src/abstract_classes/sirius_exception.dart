import 'package:sirius_backend/sirius_backend.dart';

/// An abstract base class for handling exceptions in the Sirius framework.
///
/// This class allows developers to customize how exceptions are handled
/// during the HTTP request lifecycle by implementing the [handleException]
/// method. By providing a custom implementation, you can control how
/// exceptions are logged, how error responses are structured, and whether
/// internal details are exposed to the client.
///
/// ### Use Case:
/// Implement this class to create centralized error handling logic for your app.
/// Register the implementation by passing it into the `start()` method of
/// the Sirius server.
///
/// Example:
/// ```dart
/// class MyExceptionHandler extends SiriusException {
///   @override
///   Future<Response> handleException(
///     Request request,
///     Response response,
///     int statusCode,
///     Object exception,
///     StackTrace stackTrace,
///   ) async{
///     // Log or transform the error
///     print('Error: $exception');
///     return Response.json({
///       "success": false,
///       "message": "An unexpected error occurred."
///     }, statusCode: statusCode);
///   }
/// }
///
/// void main() {
///   SiriusApp().start(
///     port: 3000,
///     exceptionHandler: MyExceptionHandler(),
///   );
/// }
/// ```
///
abstract class SiriusException {
  /// Called when an exception occurs during HTTP request processing.
  ///
  /// Implement this method to return a custom [Response] object.
  ///
  /// Parameters:
  /// - [request]: The original incoming HTTP request.
  /// - [response]: The default response object.
  /// - [statusCode]: The HTTP status code related to the exception.
  /// - [exception]: The exception that was caught.
  /// - [stackTrace]: The full stack trace at the point of failure.
  ///
  /// Returns a [Response] to be sent back to the client.
  Future<Response> handleException(Request request, Response response,
      int statusCode, Object exception, StackTrace stackTrace);
}
