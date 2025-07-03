import 'dart:io';
import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  app.post("add", (Request request) async {
    Future.delayed((Duration(seconds: 2))).then((onfs) {
      File? f = request.getFile("image");
      print(f);
    });
    return Response.sendJson(request.getAllFields);
  });

  app.start(callback: (HttpServer server) {
    print("Server is running");
  });

  fileWatcher("example/sirius.dart", callback: () {
    app.close();
  });
}
