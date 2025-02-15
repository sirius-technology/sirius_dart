import 'dart:io';

import 'constants.dart';
import 'request.dart';
import 'response.dart';
import 'router.dart';

class Server {
  final Router _router = Router();

  void group(String prefix, void Function(Server server) callback) {
    Server groupServer = Server();
    callback(groupServer);

    groupServer._router.getRoutes.forEach((key, val) {
      print("key -->> $key");
      print("val -->> $val");
    });

    // groupRouter._routes.forEach((key, handler) {
    //   _routes['$prefix$key'] = handler;
    // });
  }

  void get(String path, Future<Response> Function(Request r) handler) {
    return _router.register(GET, path, handler);
  }

  void post(String path, Future<Response> Function(Request r) handler) {
    return _router.register(POST, path, handler);
  }

  Future<void> start({int port = 8070}) async {
    var server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    print("Server is running on http://${server.address.host}:$port");

    await for (HttpRequest r in server) {
      _router.handleRequest(r);
    }
  }
}
