import 'dart:io';

import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.get("web", (Request request) async {
    Map<String, dynamic> data = {
      "name": "Somesh",
      "date": DateTime.now(),
    };

    return Response().send(data);
  });

  app.webSocket("socket", (WebSocket socket) {
    socket.listen((onData) {
      Future.delayed(Duration(seconds: 2)).then((onValue) {
        socket.add("Sirius : $onData");
        // socket.close(1, "NO REASON");
      });
    });
  });

  app.start(
    port: 9000,
    callback: (server) {
      print("Server is running");
    },
  );

  await fileWatcher("example/sirius_example.dart", callback: () {
    app.close();
  });
}
