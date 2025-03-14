import 'dart:io';

import 'package:sirius/src/logging.dart';
import 'package:sirius/src/middleware.dart';

import 'constants.dart';
import 'request.dart';
import 'response.dart';
import 'router.dart';

class Sirius {
  final Map<String, Map<String, Future<Response> Function(Request r)>>
      _routesMap = {};
  final List<Middleware> _middlewaresList = [];

  final Router _router = Router();

  HttpServer? _server;

  String _autoAddSlash(String path) {
    if (path.startsWith("/")) {
      return path;
    }
    return "/$path";
  }

  void use(Middleware middleware) {
    _middlewaresList.add(middleware);
  }

  void group(String prefix, void Function(Sirius sirius) callback) {
    prefix = _autoAddSlash(prefix);

    Sirius groupRoutes = Sirius();
    callback(groupRoutes);

    groupRoutes._routesMap.forEach((key, value) {
      _routesMap["$prefix$key"] = value;
    });
  }

  void get(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);

    if (_routesMap.containsKey(path)) {
      if (_routesMap[path]!.containsKey(GET)) {
        throwError("path {$path} and method {$POST} is already registered.");
      } else {
        _routesMap[path]![GET] = handler;
      }
      return;
    }
    _routesMap[path] = {GET: handler};
  }

  void post(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);

    if (_routesMap.containsKey(path)) {
      if (_routesMap[path]!.containsKey(POST)) {
        throwError("path {$path} and method {$POST} is already registered.");
      } else {
        _routesMap[path]![POST] = handler;
      }
      return;
    }
    _routesMap[path] = {POST: handler};
  }

  void put(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);

    if (_routesMap.containsKey(path)) {
      if (_routesMap[path]!.containsKey(PUT)) {
        throwError("path {$path} and method {$PUT} is already registered.");
      } else {
        _routesMap[path]![PUT] = handler;
      }
      return;
    }
    _routesMap[path] = {PUT: handler};
  }

  void delete(String path, Future<Response> Function(Request request) handler) {
    path = _autoAddSlash(path);

    if (_routesMap.containsKey(path)) {
      if (_routesMap[path]!.containsKey(DELETE)) {
        throwError("path {$path} and method {$DELETE} is already registered.");
      } else {
        _routesMap[path]![DELETE] = handler;
      }
      return;
    }
    _routesMap[path] = {DELETE: handler};
  }

  Future<void> start({int port = 8070, Function()? callback}) async {
    _router.registerRoutes(_routesMap);
    _router.registerMiddlewares(_middlewaresList);

    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    if (callback != null) {
      callback();
    }

    await for (HttpRequest request in _server!) {
      _router.handleRequest(request);
    }
  }

  Future<void> close() async {
    if (_server != null) {
      await _server!.close();
    }
  }
}
