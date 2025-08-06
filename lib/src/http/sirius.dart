import 'dart:io';

import 'package:sirius_backend/src/constants/constant_methods.dart';
import 'package:sirius_backend/src/http/handler.dart';

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

  final Map<String, Map<String, (List<WrapperFunction>, HttpHandlerFunction)>>
      _routesMap = {};

  final List<WrapperFunction> _wrapperList = [];

  final Map<String, SocketHandlerFunction> _socketRoutesMap = {};

  final Handler _handler = Handler();

  HttpServer? _server;

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

    siriusGroup._socketRoutesMap.forEach((path, function) {
      _socketRoutesMap["$prefix$path"] = function;
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
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler, wrappers);
  }

  /// Registers a POST route.
  void post(
    String path,
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, POST, handler, wrappers);
  }

  /// Registers a PUT route.
  void put(
    String path,
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PUT, handler, wrappers);
  }

  /// Registers a PATCH route.
  void patch(
    String path,
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PATCH, handler, wrappers);
  }

  /// Registers a DELETE route.
  void delete(
    String path,
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, DELETE, handler, wrappers);
  }

  /// Registers a head route.
  void head(
    String path,
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, HEAD, handler, wrappers);
  }

  /// Registers a options route.
  void options(
    String path,
    HttpHandlerFunction handler, {
    List<WrapperFunction> wrappers = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, OPTIONS, handler, wrappers);
  }

  void _addRoute(
    String path,
    String method,
    HttpHandlerFunction mainHandler,
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
        _routesMap[method]![path] = (wrapperList, mainHandler);
      }
      return;
    }
    _routesMap[method] = {path: (wrapperList, mainHandler)};
  }

  /// Registers a WebSocket route.
  ///
  /// Example:
  /// ```dart
  /// sirius.webSocket('/chat', (WebSocketRequest request, WebSocket webSocket) {
  ///   webSocket.listen((data) {
  ///     webSocket.add("Echo: $data");
  ///   });
  /// });
  /// ```
  void webSocket(String path, SocketHandlerFunction handler) {
    path = _autoAddSlash(path);

    if (_socketRoutesMap.containsKey(path)) {
      throw Exception("WebSocket path {$path} is already registered.");
    } else {
      _socketRoutesMap[path] = handler;
    }
  }

  /// Starts the HTTP server on the specified port.
  ///
  /// Default port is `3333`. You can also provide a callback to run after startup.
  ///
  /// ```dart
  /// await sirius.start(port: 8080, callback: (server) {
  ///   print('Server running at ${server.address.address}:${server.port}');
  /// });
  /// ```
  Future<void> start({
    int port = 3333,
    Function(HttpServer server)? callback,
    ExceptionHandlerFunction? exceptionHandler,
    void Function()? onClosed,
    Function? onError,
  }) async {
    _removeTempFolder();
    _handler.registerRoutes(_routesMap, _socketRoutesMap, exceptionHandler);
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

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

  Future<void> _removeTempFolder() async {
    final tempDir = Directory('temp');

    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  }
}
