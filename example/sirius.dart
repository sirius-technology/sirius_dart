import 'dart:async';

import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.wrap((req, next) {
    print('MIDDLEWARE');
    return next();
  });

  app.webSocket('ws', (Request req) async {
    final WsConnection ws = await req.upgradeToWebSocket();

    ws.on('sent_room', (Object? data) {
      ws.to(ws.rooms.first).emitExceptMe('message', data);
    });

    ws.on('join_room', (Object? data) {
      if (data == null) {
        ws.send('Data is required');
        return;
      }
      if (data is! Map) {
        ws.send('Data should be a map');
        return;
      }
      if (data['room'] == null) {
        ws.send('Room is required');
        return;
      }
      if (data['room'] is! String) {
        ws.send('Room should be a string');
        return;
      }

      ws.join(data['room'] as String);
      print('ROOM JOINED -> ${data['room']}');
    });
  });

  app.start();
}
