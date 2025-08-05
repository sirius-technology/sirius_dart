import 'dart:io';
import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  app.get('get', (req) async {
    return Response.send(null);
  });

  app.head('head', (req) async {
    Response res = Response();
    // res.headers = req.headers;
    res.statusCode = 200;
    return res;
  });

  app.options('options', (req) async {
    return Response.send('');
  });

  app.start(callback: (HttpServer server) {
    print("Server is running");
  });
}
