import 'dart:io';

import 'package:sirius_backend/src/constants/constant_methods.dart';
import 'package:sirius_backend/src/helpers/logging.dart';
import 'package:sirius_backend/src/http/handler.dart';

/// ---------------------------------------------------------------------------
/// Sirius
/// ---------------------------------------------------------------------------
///
/// **Sirius** is a lightweight, extensible HTTP + WebSocket backend framework
/// for Dart designed for performance, clarity, and flexibility.
///
/// It provides a minimal core while still supporting modern backend features:
///
/// • Routing by HTTP method
/// • Route groups (prefix-based)
/// • Middleware wrappers
/// • WebSocket endpoints
/// • Structured handler pipeline
/// • Graceful server lifecycle management
///
/// Sirius is intentionally designed to feel familiar to developers coming from
/// frameworks like Express.js, Fastify, or Hono — while remaining purely Dart.
///
/// ---------------------------------------------------------------------------
/// 🚀 Quick Start
/// ---------------------------------------------------------------------------
/// ```dart
/// final app = Sirius();
///
/// app.get('/hello', (req) async {
///   return Response.send('Hello World');
/// });
///
/// await app.start(port: 3000);
/// ```
///
/// ---------------------------------------------------------------------------
/// 📁 Route Groups
/// ---------------------------------------------------------------------------
/// Group routes under a shared prefix:
///
/// ```dart
/// app.group('/api', (api) {
///   api.get('/users', userController.list);
///   api.post('/users', userController.create);
/// });
/// ```
///
/// Final paths:
/// ```
/// /api/users
/// ```
///
/// ---------------------------------------------------------------------------
/// 🧩 Middleware Wrappers
/// ---------------------------------------------------------------------------
/// Wrappers behave like interceptors that wrap request execution.
/// They are ideal for:
///
/// • Logging
/// • Authentication
/// • Metrics
/// • Error handling
/// • Timing measurement
///
/// ```dart
/// app.wrap((handler) {
///   return (req) async {
///     final start = DateTime.now();
///     final res = await handler(req);
///     print(DateTime.now().difference(start));
///     return res;
///   };
/// });
/// ```
///
/// Wrappers are executed in order of registration.
///
/// ---------------------------------------------------------------------------
/// 🔌 WebSocket Support
/// ---------------------------------------------------------------------------
/// WebSocket routes use the same routing system as HTTP routes
/// but internally upgrade the request.
///
/// ```dart
/// app.webSocket('/chat', (req) async {
///   final ws = await req.upgradeToWebSocket();
///
///   ws.onEvent('message', (data) {
///     ws.sendEvent('reply', {'echo': data});
///   });
/// });
/// ```
///
/// ---------------------------------------------------------------------------
/// 🧠 Internal Architecture Overview
/// ---------------------------------------------------------------------------
/// Internally Sirius stores routes as:
///
/// ```dart
/// Map<method, Map<path, (wrappers, handler)>>
/// ```
///
/// This allows:
/// • O(1) method lookup
/// • fast path matching
/// • efficient wrapper execution
///
/// The heavy lifting is delegated to the internal [Handler] class.
///
/// ---------------------------------------------------------------------------
/// ⚠ Lifecycle Notes
/// ---------------------------------------------------------------------------
/// • A single [Sirius] instance represents one server
/// • Do not call `start()` twice
/// • Always call `close()` for graceful shutdown in production
/// ---------------------------------------------------------------------------
class Sirius {
  /// Sirius is a lightweight and extensible HTTP and WebSocket server framework for Dart.
  ///
  /// It supports middleware, route grouping, and request-response management.
  /// Built to resemble modern web frameworks like Express.js, it is simple yet powerful.
  ///
  /// ### Example: Basic HTTP server
  /// ```dart
  /// final sirius = Sirius();
  ///
  /// sirius.get('/hello', (req) async => Response.send('Hello World'));
  ///
  /// await sirius.start(port: 3000);
  /// ```
  ///
  /// ### Example: Grouped routes
  /// ```dart
  /// sirius.group('/api', (group) {
  ///   group.get('/users', userController.getAll);
  ///   group.post('/users', userController.create);
  /// });
  /// ```
  Sirius();

  /// Route storage map.
  ///
  /// Structure:
  /// ```dart
  /// method -> path -> (wrappers, handler)
  /// ```
  final Map<
      String,
      Map<
          String,
          (
            List<WrapperFunction>,
            HandlerFunction?,
          )>> _routesMap = {};

  /// Global wrapper middleware applied to every route.
  final List<WrapperFunction> _wrapperList = [];

  /// Core request handler responsible for dispatching routes.
  final Handler _handler = Handler();

  /// Underlying Dart HTTP server instance.
  HttpServer? _server;

  /// Ensures route path starts with `/`.
  String _autoAddSlash(String path) {
    if (path.startsWith("/")) {
      return path;
    }
    return "/$path";
  }

  /// Registers a global wrapper middleware that wraps the entire handler chain.
  ///
  /// Wrappers act like interceptors and are ideal for timing, monitoring, etc.
  ///
  /// ```dart
  /// sirius.wrap(TimerWrapper().handle);
  /// ```
  void wrap(WrapperFunction wrapper) {
    _wrapperList.add(wrapper);
  }

  /// Groups multiple routes under a common prefix.
  ///
  /// Useful for organizing APIs like `/api/v1`, `/admin`, etc.
  ///
  /// ```dart
  /// sirius.group('/api', (api) {
  ///   api.get('/users', userController.getUserHandler);
  ///   api.post('/users', userController.createUserHandler);
  /// });
  /// ```
  void group(String prefix, void Function(Sirius sirius) callback) {
    prefix = _autoAddSlash(prefix);

    Sirius siriusGroup = Sirius();

    siriusGroup._wrapperList.addAll(_wrapperList);

    callback(siriusGroup);

    siriusGroup._routesMap.forEach((method, pathMap) {
      for (final entry in pathMap.entries) {
        final String fullPath = "$prefix${entry.key}";
        _routesMap.putIfAbsent(method, () => {});
        _routesMap[method]![fullPath] = entry.value;
      }
    });
  }

  /// Registers a GET route in the Sirius application.
  ///
  /// Optionally, you can pass route-specific wrappers (middleware) using the [wrappers] parameter.
  ///
  /// Example:
  /// ```dart
  /// sirius.get('/users', handler, wrappers: [checkAuth()]);
  /// ```
  ///
  /// Parameters:
  /// - [path]     → The route path (e.g. `/users`)
  /// - [handler]  → The function that handles the request
  /// - [wrappers] → Optional list of wrapper functions (middleware) applied only to this route
  void get(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler, wrappers);
  }

  /// Registers a POST route.
  void post(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, POST, handler, wrappers);
  }

  /// Registers a PUT route.
  void put(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PUT, handler, wrappers);
  }

  /// Registers a PATCH route.
  void patch(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PATCH, handler, wrappers);
  }

  /// Registers a DELETE route.
  void delete(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, DELETE, handler, wrappers);
  }

  /// Registers a head route.
  void head(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, HEAD, handler, wrappers);
  }

  /// Registers a options route.
  void options(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, OPTIONS, handler, wrappers);
  }

  /// Registers a WebSocket endpoint.
  ///
  /// Internally uses GET method routing.
  void webSocket(
    String path,
    HandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler, wrappers);
  }

  /// Internal route registration logic.
  void _addRoute(
    String path,
    String method,
    HandlerFunction? handler,
    List<WrapperFunction> routeWrappersList,
  ) {
    List<WrapperFunction> wrapperList = [
      ..._wrapperList,
      ...routeWrappersList,
    ];

    if (_routesMap.containsKey(method)) {
      if (_routesMap[method]!.containsKey(path)) {
        throw Exception(
            "method {$method} and path {$path} is already registered.");
      } else {
        _routesMap[method]![path] = (wrapperList, handler);
      }
      return;
    }
    _routesMap[method] = {path: (wrapperList, handler)};
  }

  // -------------------------------------------------------------------------
  // Server Lifecycle
  // -------------------------------------------------------------------------

  /// Starts the HTTP server.
  ///
  /// This initializes routing, binds the server to the specified port,
  /// and begins listening for incoming HTTP requests.
  ///
  /// Parameters:
  /// • [port] → Port number to listen on (default: `3333`)
  /// • [callback] → Runs immediately after server starts
  /// • [exceptionHandler] → Global exception handler for route errors
  /// • [onClosed] → Called when server shuts down
  /// • [onError] → Low‑level server errors
  ///
  /// -----------------------------------------------------------------------
  /// Example — Basic Server Startup
  /// -----------------------------------------------------------------------
  /// ```dart
  /// final app = Sirius();
  ///
  /// app.get('/hello', (req) async => Response.send('Hello'));
  ///
  /// await app.start(
  ///   port: 8080,
  ///   callback: (server) {
  ///     print('Server running on ${server.port}');
  ///   },
  /// );
  /// ```
  ///
  /// -----------------------------------------------------------------------
  /// Example — Production Setup
  /// -----------------------------------------------------------------------
  /// ```dart
  /// await app.start(
  ///   port: 80,
  ///   exceptionHandler: (error, stack) {
  ///     print('Global error: $error');
  ///   },
  ///   onClosed: () => print('Server stopped'),
  /// );
  /// ```
  Future<void> start({
    int port = 3333,
    Function(HttpServer server)? callback,
    ExceptionHandlerFunction? exceptionHandler,
    void Function()? onClosed,
    Function? onError,
  }) async {
    _removeTempFolder();
    _handler.registerRoutes(_routesMap, exceptionHandler);

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } on SocketException catch (e) {
      if (e.osError?.errorCode == 48) {
        logError(
            "⚠️ Port $port is already in use. Please stop the previous server or use a different port");
        return;
      }
      rethrow;
    }

    if (callback != null) {
      callback(_server!);
    }

    _server!.listen(
      (HttpRequest request) {
        _handler.handleRequest(request);
      },
      onDone: onClosed,
      onError: onError,
    );
  }

  /// Closes the server gracefully.
  ///
  /// Use `force: true` to immediately terminate all connections.
  Future<void> close({bool force = false}) async {
    if (_server != null) {
      await _server!.close(force: force);
    }
  }

  /// Access the raw [HttpServer] instance.
  HttpServer? get rawHttpServer => _server;

  /// Deletes temp directory created for uploaded files.
  Future<void> _removeTempFolder() async {
    final tempDir = Directory('temp');

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}
