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

    throw Exception('EXCEP');

    // return null;
  });
}
