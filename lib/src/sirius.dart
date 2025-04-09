import 'dart:io';

import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/constants.dart';
import 'package:sirius_backend/src/handler.dart';
import 'package:sirius_backend/src/helpers/logging.dart';

/// Sirius is a lightweight HTTP and WebSocket server framework for Dart.
///
/// It provides easy-to-use routing, middleware support, and WebSocket handling.
///
/// ### Basic Example:
///
/// ```dart
/// final Sirius sirius = Sirius();
///
/// sirius.get('/hello', (req) async => Response.send('Hello World'));
///
/// await sirius.start(port: 3000);
/// ```
///
/// ### Grouped Routes:
/// ```dart
/// sirius.group('/api', (group) {
///   group.get('/users', userController.getUsersHandler);
///   group.post('/users', userController.createUserHandler);
/// });
/// ```
class Sirius {
  final Map<String,
          Map<String, List<Future<Response> Function(Request request)>>>
      _routesMap = {};
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

  /// Registers a middleware to run before each request.
  void useBefore(Middleware middleware) {
    _beforeMiddlewareList.add(middleware.handle);
  }

  /// Registers a middleware to run after each request.
  void useAfter(Middleware middleware) {
    _afterMiddlewareList.add(middleware.handle);
  }

  /// Groups routes under a common prefix.
  ///
  /// ```dart
  /// sirius.group('/api', (group) {
  ///   group.get('/users', userController.getUsersHandler);
  /// });
  /// ```
  void group(String prefix, void Function(Sirius sirius) callback) {
    prefix = _autoAddSlash(prefix);

    Sirius siriusGroup = Sirius();

    siriusGroup._beforeMiddlewareList.addAll(_beforeMiddlewareList);
    siriusGroup._afterMiddlewareList.addAll(_afterMiddlewareList);

    callback(siriusGroup);

    siriusGroup._routesMap.forEach((key, value) {
      _routesMap["$prefix$key"] = value;
    });
    siriusGroup._socketRoutesMap.forEach((key, value) {
      _socketRoutesMap["$prefix$key"] = value;
    });
  }

  /// Registers a GET route.
  void get(String path, Future<Response> Function(Request request) handler,
      {List<Middleware> useBefore = const [],
      List<Middleware> useAfter = const []}) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler, useBefore, useAfter);
  }

  /// Registers a POST route.
  void post(String path, Future<Response> Function(Request request) handler,
      {List<Middleware> useBefore = const [],
      List<Middleware> useAfter = const []}) {
    path = _autoAddSlash(path);
    _addRoute(path, POST, handler, useBefore, useAfter);
  }

  /// Registers a PUT route.
  void put(String path, Future<Response> Function(Request request) handler,
      {List<Middleware> useBefore = const [],
      List<Middleware> useAfter = const []}) {
    path = _autoAddSlash(path);
    _addRoute(path, PUT, handler, useBefore, useAfter);
  }

  /// Registers a DELETE route.
  void delete(String path, Future<Response> Function(Request request) handler,
      {List<Middleware> useBefore = const [],
      List<Middleware> useAfter = const []}) {
    path = _autoAddSlash(path);
    _addRoute(path, DELETE, handler, useBefore, useAfter);
  }

  void _addRoute(
    String path,
    String method,
    Future<Response> Function(Request request) handler,
    List<Middleware> beforeMiddlewares,
    List<Middleware> afterMiddlewares,
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

    if (_routesMap.containsKey(path)) {
      if (_routesMap[path]!.containsKey(method)) {
        throwError("path {$path} and method {$method} is already registered.");
      } else {
        _routesMap[path]![method] = middlewareHandlerList;
      }
      return;
    }
    _routesMap[path] = {method: middlewareHandlerList};
  }

  /// Registers a WebSocket route.
  ///
  /// ```dart
  /// sirius.webSocket('/chat', (socket) {
  ///   socket.listen((message) => socket.add('Echo: \$message'));
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

  /// Starts the server on the given [port].
  ///
  /// ```dart
  /// await sirius.start(port: 3000);
  /// ```
  Future<void> start(
      {int port = 8070, Function(HttpServer server)? callback}) async {
    _handler.registerRoutes(_routesMap, _socketRoutesMap);
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    if (callback != null) {
      callback(_server!);
    }

    await for (HttpRequest request in _server!) {
      _handler.handleRequest(request);
    }
  }

  /// Closes the HTTP server gracefully.
  Future<void> close({bool force = false}) async {
    if (_server != null) {
      await _server!.close(force: force);
    }
  }
}
