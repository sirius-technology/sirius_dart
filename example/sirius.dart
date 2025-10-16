import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  // app.wrap((req, next) async {
  //   final res = await next();

  //   return res;
  // });

  app.get('get', (req) async {
    // req.ge
    return Response.sendJson(req);
  });

  // app.start(callback: (server) {
  //   print("Server is running");
  // });
}
