import 'dart:io';

import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/constants.dart';
import 'package:sirius_backend/src/handler.dart';
import 'package:sirius_backend/src/helpers/logging.dart';
import 'package:sirius_backend/src/wrapper.dart';

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
  final Map<
      String,
      Map<
          String,
          (
            List<
                Future<Response> Function(
                    Request request, Future<Response> Function() nextHandler)>,
            List<Future<Response> Function(Request request)>
          )>> _routesMap = {};

  final List<
          Future<Response> Function(
              Request request, Future<Response> Function() nextHandler)>
      _wrapperList = [];

  final Map<String, void Function(WebSocket socket)> _socketRoutesMap = {};
  final List<Future<Response> Function(Request request)> _beforeMiddlewareList =
      [];
  final List<Future<Response> Function(Request request)> _afterMiddlewareList =
      [];
  final Handler _handler = Handler();
  HttpServer? _server;

  String _autoAddSlash(String path) {
    if (path.startsWith("/")) {
      return path;
    }
    return "/$path";
  }

  /// Registers a global middleware that runs before every route handler.
  ///
  /// This is useful for authentication, request logging, etc.
  ///
  /// ```dart
  /// sirius.useBefore(LoggerMiddleware());
  /// ```
  void useBefore(Middleware middleware) {
    _beforeMiddlewareList.add(middleware.handle);
  }

  /// Registers a global middleware that runs after every route handler.
  ///
  /// This can be useful for logging responses, cleanup, etc.
  ///
  /// ```dart
  /// sirius.useAfter(ResponseLogger());
  /// ```
  void useAfter(Middleware middleware) {
    _afterMiddlewareList.add(middleware.handle);
  }

  /// Registers a global wrapper middleware that wraps the entire handler chain.
  ///
  /// Wrappers act like interceptors and are ideal for timing, monitoring, etc.
  ///
  /// ```dart
  /// sirius.wrap(TimerWrapper());
  /// ```
  void wrap(Wrapper wrapper) {
    _wrapperList.add(wrapper.handle);
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

    siriusGroup._beforeMiddlewareList.addAll(_beforeMiddlewareList);
    siriusGroup._afterMiddlewareList.addAll(_afterMiddlewareList);

    callback(siriusGroup);

    siriusGroup._routesMap.forEach((method, pathMap) {
      siriusGroup._wrapperList.addAll(_wrapperList);

      for (final entry in pathMap.entries) {
        final fullPath = "$prefix${entry.key}";
        _routesMap.putIfAbsent(method, () => {});
        _routesMap[method]![fullPath] = entry.value;
      }
    });

    siriusGroup._socketRoutesMap.forEach((path, function) {
      _socketRoutesMap["$prefix$path"] = function;
    });
  }

  /// Registers a GET route.
  ///
  /// You can also pass route-specific middleware and wrapper.
  ///
  /// ```dart
  /// sirius.get('/users', handler, useBefore: [CheckAuth()]);
  /// ```
  void get(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
    List<Wrapper> wrap = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler, useBefore, useAfter, wrap);
  }

  /// Registers a POST route.
  void post(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
    List<Wrapper> wrap = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, POST, handler, useBefore, useAfter, wrap);
  }

  /// Registers a PUT route.
  void put(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
    List<Wrapper> wrap = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PUT, handler, useBefore, useAfter, wrap);
  }

  /// Registers a PATCH route.
  void patch(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
    List<Wrapper> wrap = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PATCH, handler, useBefore, useAfter, wrap);
  }

  /// Registers a DELETE route.
  void delete(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
    List<Wrapper> wrap = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, DELETE, handler, useBefore, useAfter, wrap);
  }

  void _addRoute(
    String path,
    String method,
    Future<Response> Function(Request request) handler,
    List<Middleware> beforeMiddlewares,
    List<Middleware> afterMiddlewares,
    List<Wrapper> wrappers,
  ) {
    List<Future<Response> Function(Request request)> beforeRouteMiddlewareList =
        beforeMiddlewares.map((mw) => mw.handle).toList();

    List<Future<Response> Function(Request request)> afterRouteMiddlewareList =
        afterMiddlewares.map((mw) => mw.handle).toList();

    List<Future<Response> Function(Request request)> middlewareHandlerList = [
      ..._beforeMiddlewareList,
      ...beforeRouteMiddlewareList,
      handler,
      ...afterRouteMiddlewareList,
      ..._afterMiddlewareList,
    ];

    List<
            Future<Response> Function(
                Request request, Future<Response> Function() nextHandler)>
        wrapperList = [..._wrapperList, ...wrappers.map((wr) => wr.handle)];

    if (_routesMap.containsKey(method)) {
      if (_routesMap[path]!.containsKey(path)) {
        throwError("method {$method} and path {$path} is already registered.");
      } else {
        // _routesMap[path]![method] = middlewareHandlerList;
        _routesMap[method]![path] = (wrapperList, middlewareHandlerList);
      }
      return;
    }
    _routesMap[method] = {path: (wrapperList, middlewareHandlerList)};
  }

  /// Registers a WebSocket route.
  ///
  /// Example:
  /// ```dart
  /// sirius.webSocket('/chat', (socket) {
  ///   socket.listen((data) {
  ///     socket.add("Echo: $data");
  ///   });
  /// });
  /// ```
  void webSocket(String path, void Function(WebSocket socket) handler) {
    path = _autoAddSlash(path);

    if (_socketRoutesMap.containsKey(path)) {
      throwError("WebSocket path {$path} is already registered.");
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
  }) async {
    _handler.registerRoutes(_routesMap, _socketRoutesMap);
    logMap2(_routesMap);
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    if (callback != null) {
      callback(_server!);
    }

    await for (HttpRequest request in _server!) {
      _handler.handleRequest(request);
    }
  }

  /// Closes the server gracefully.
  ///
  /// Use `force: true` to immediately terminate all connections.
  Future<void> close({bool force = false}) async {
    if (_server != null) {
      await _server!.close(force: force);
    }
  }
}
