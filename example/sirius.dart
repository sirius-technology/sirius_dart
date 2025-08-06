import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  app.wrap((req, next) async {
    final res = await next();

    return res;
  });

  app.get('get', (req) async {
    return Response.sendJson(req);
  });

  app.start(callback: (server) {
    print("Server is running");
  });
}
