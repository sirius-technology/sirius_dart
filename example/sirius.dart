import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  Validator.enableTypeSafety = false;

  // app.wrap(TimeOutWrapper().handle);

  app.post("/", (request) async {
    return Response.sendJson("SUCCESS");
  });

  app.start(
    callback: (server) {
      print("server is running");
    },
  );

  fileWatcher("example/sirius.dart", callback: () async {
    await app.close();
  });
}

class TimeOutWrapper extends Wrapper {
  @override
  Future<Response> handle(
      Request request, Future<Response> Function() nextHandler) {
    return nextHandler().timeout(
      Duration(seconds: 2),
      onTimeout: () {
        return Response.sendJson("TIMEOUT");
      },
    );
  }
}
