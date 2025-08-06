import 'package:sirius_backend/sirius_backend.dart';

/// Creates a reusable CORS (Cross-Origin Resource Sharing) handler middleware
/// for the Sirius backend framework.
///
/// This handler adds the necessary CORS headers to every HTTP response
/// and correctly handles `OPTIONS` preflight requests by returning a
/// `204 No Content` response with the appropriate CORS headers.
///
/// ### Usage
/// ```dart
/// import 'package:sirius_backend/inbuilds/cors_handler.dart';
///
/// void main() {
///   final app = Sirius();
///
///   app.wrap(corsHandler()); // Apply CORS globally
///
///   app.get('ping', (req) async => Response.send('pong'));
///
///   app.start();
/// }
/// ```
///
/// ### Parameters:
/// - [allowOrigin] (default: `*`): The value of the `Access-Control-Allow-Origin` header.
///   Set this to a specific domain (e.g., `https://example.com`) in production.
///
/// - [allowMethods] (default: `'GET, POST, PUT, DELETE, OPTIONS'`):
///   Specifies the allowed HTTP methods.
///
/// - [allowHeaders] (default: `'Origin, Content-Type, Accept, Authorization'`):
///   Specifies which request headers are allowed in cross-origin requests.
///
/// - [allowCredentials] (default: `false`):
///   If set to `true`, adds `Access-Control-Allow-Credentials: true`
///   allowing cookies and credentials in cross-origin requests.
///
/// ### Returns:
/// A middleware function that can be passed to `.wrap()` in a Sirius app.
Future<Response> Function(
  Request request,
  Future<Response> Function() nextHandler,
) corsHandler({
  String allowOrigin = '*',
  String allowMethods = 'GET, POST, PUT, DELETE, OPTIONS',
  String allowHeaders = 'Origin, Content-Type, Accept, Authorization',
  bool allowCredentials = false,
}) {
  return (Request request, Future<Response> Function() nextHandler) async {
    if (request.method == 'OPTIONS') {
      final response = Response();
      response.statusCode = 204;
      response.addHeader('Access-Control-Allow-Origin', allowOrigin);
      response.addHeader('Access-Control-Allow-Methods', allowMethods);
      response.addHeader('Access-Control-Allow-Headers', allowHeaders);
      if (allowCredentials) {
        response.addHeader('Access-Control-Allow-Credentials', 'true');
      }
      return response;
    }

    final response = await nextHandler();

    response.addHeader('Access-Control-Allow-Origin', allowOrigin);
    response.addHeader('Access-Control-Allow-Methods', allowMethods);
    response.addHeader('Access-Control-Allow-Headers', allowHeaders);
    if (allowCredentials) {
      response.addHeader('Access-Control-Allow-Credentials', 'true');
    }
    return response;
  };
}
