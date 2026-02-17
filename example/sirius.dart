import 'dart:async';

import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.wrap((req, next) {
    print('MIDDLEWARE');
    return next();
  });

  // app.get('file', (req) async {
  //   return Response.sendFile(
  //       File('/Users/someshsahu/_Beaming_India/_PROJECTS/VEDASAR/vedasar.png'),
  //       inline: true);
  // });

  app.get('path', (req) {
    return Response.send('data');
  });

  app.webSocket('ws', (req) async {
    final ws = await req.upgradeToWebSocket();
    ws.onData((data) {
      ws.sendData('From Server : $data');
    });
    return null;
  });

  app.start(callback: (server) {
    print("Server is running");
  });
}

// NEED TO MAKE WEBSOCKET CONN CLASS TO ALOW DEVELOPERS TO CONNECT WEBSOCKET INSIDE HANDLER
