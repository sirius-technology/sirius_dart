import 'dart:async';

import 'package:sirius_backend/sirius_backend.dart';

/// ---------------------------------------------------------------------------
/// Wrapper Middleware
/// ---------------------------------------------------------------------------
///
/// Base class for creating middleware wrappers in the Sirius framework.
///
/// A [Wrapper] intercepts incoming HTTP requests **before** they reach the
/// final route handler and may also inspect or modify the outgoing [Response].
///
/// Wrappers are commonly used for:
/// • Authentication / Authorization
/// • Logging & monitoring
/// • CORS handling
/// • Input validation
/// • Rate limiting
/// • Error handling
///
/// ---------------------------------------------------------------------------
/// 🧠 Execution Flow
/// ---------------------------------------------------------------------------
///
/// ```text
/// Request → Wrapper1 → Wrapper2 → Route Handler → Response → Wrapper2 → Wrapper1
/// ```
///
/// Each wrapper controls whether execution continues by calling [nextHandler].
///
/// ---------------------------------------------------------------------------
/// ⛔ Short-Circuiting
/// ---------------------------------------------------------------------------
///
/// A wrapper may return a [Response] **without** calling [nextHandler]
/// to immediately stop execution.
///
/// Example:
/// ```dart
/// if (!isAuthorized) {
///   return Response.sendJson({'error': 'Unauthorized'}, statusCode: 401);
/// }
/// ```
///
/// ---------------------------------------------------------------------------
/// ✅ Continue Execution
/// ---------------------------------------------------------------------------
///
/// To allow processing to continue to the next wrapper or handler:
///
/// ```dart
/// return await nextHandler();
/// ```
///
/// ---------------------------------------------------------------------------
/// 🧪 Example Implementation
/// ---------------------------------------------------------------------------
///
/// ```dart
/// class AuthWrapper extends Wrapper {
///   @override
///   FutureOr<Response?> handle(
///     Request request,
///     FutureOr<Response?> Function() nextHandler,
///   ) async {
///     if (!request.headers.containsKey('Authorization')) {
///       return Response.sendJson({'error': 'Unauthorized'}, statusCode: 401);
///     }
///
///     return await nextHandler();
///   }
/// }
/// ```
///
/// ---------------------------------------------------------------------------
/// ⚠ Important Rules
/// ---------------------------------------------------------------------------
///
/// • Always return a [Response] or the result of [nextHandler()]
/// • Do NOT call [nextHandler] more than once
/// • You may modify the request before forwarding
/// • You may modify the response after awaiting nextHandler
/// • Returning `null` means no response was produced
///
/// ---------------------------------------------------------------------------
abstract class Wrapper {
  /// Processes an incoming [request] and controls execution flow.
  ///
  /// Parameters:
  /// • [request] → Incoming HTTP request
  /// • [nextHandler] → Executes next wrapper or final route handler
  ///
  /// Returns:
  /// • a [Response] to send immediately
  /// • or result of [nextHandler()]
  /// • or `null` if nothing handled the request
  ///
  /// This method may be synchronous or asynchronous.
  FutureOr<Response?> handle(
    Request request,
    FutureOr<Response?> Function() nextHandler,
  );
}
