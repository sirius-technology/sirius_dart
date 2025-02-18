import 'dart:io';

import 'package:sirius/src/logging.dart';

import 'constants.dart';
import 'request.dart';
import 'response.dart';
import 'router.dart';

class Server {
  final Map<String, Map<String, Future<Response> Function(Request r)>>
      _routesMap = {};

  final Router _router = Router();

  void group(String prefix, void Function(Server server) callback) {
    Server groupRoutes = Server();
    callback(groupRoutes);

    groupRoutes._routesMap.forEach((key, value) {
      String newPath = "$prefix$key";

      // if (_routesMap.containsKey(newPath)) {
      //   // value.forEach((key2, value2) {
      //   //   if (_routesMap[newPath]!.containsKey(key2)) {
      //   //     throwError(
      //   //         "Path {$newPath} with method {$key2} is already registered.");
      //   //   } else {
      //   //     _routesMap[newPath]![key2] = value2;
      //   //   }
      //   // });
      // }

      _routesMap["$prefix$key"] = value;
    });
  }

  void get(String path, Future<Response> Function(Request r) handler) {
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

  void post(String path, Future<Response> Function(Request r) handler) {
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

  Future<void> start({int port = 8070}) async {
    _router.register(_routesMap);

    var server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    print("Server is running on http://${server.address.host}:$port");

    await for (HttpRequest r in server) {
      _router.handleRequest(r);
    }
  }
}
