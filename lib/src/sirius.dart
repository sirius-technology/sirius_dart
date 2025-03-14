import 'dart:io';

import 'package:sirius/src/helpers/logging.dart';
import 'package:sirius/src/middleware.dart';

import 'constants.dart';
import 'request.dart';
import 'response.dart';
import 'handler.dart';

class Sirius {
  final Map<String,
          Map<String, List<Future<Response> Function(Request request)>>>
      _routesMap = {};

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

  void useBefore(Middleware middleware) {
    _beforeMiddlewareList.add(middleware.handle);
  }

  void useAfter(Middleware middleware) {
    _afterMiddlewareList.add(middleware.handle);
  }

  void group(String prefix, void Function(Sirius sirius) callback) {
    prefix = _autoAddSlash(prefix);

    Sirius groupRoutes = Sirius();

    groupRoutes._beforeMiddlewareList.addAll(_beforeMiddlewareList);
    groupRoutes._afterMiddlewareList.addAll(_afterMiddlewareList);

    callback(groupRoutes);

    groupRoutes._routesMap.forEach((key, value) {
      _routesMap["$prefix$key"] = value;
    });
  }

  void get(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler);
  }

  void post(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);
    _addRoute(path, POST, handler);
  }

  void put(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);
    _addRoute(path, PUT, handler);
  }

  void delete(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);
    _addRoute(path, DELETE, handler);
  }

  void _addRoute(String path, String method,
      Future<Response> Function(Request request) handler) {
    List<Future<Response> Function(Request request)> middlewareHandlerList = [
      ..._beforeMiddlewareList,
      handler,
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

  Future<void> start({int port = 8070, Function()? callback}) async {
    _handler.registerRoutes(_routesMap);

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    if (callback != null) {
      callback();
    }

    await for (HttpRequest request in _server!) {
      _handler.handleRequest(request);
    }
  }

  Future<void> close() async {
    if (_server != null) {
      await _server!.close();
    }
  }
}
