import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius sirius = Sirius();

  // sirius.useBefore(Logger());

  sirius.post("test", (Request request) async {
    return Response.send(request.jsonBody);
  });

  sirius.group("api", (r) {
    r.post("test", (Request request) async {
      return Response.send(request.jsonBody);
    });
    r.put("test/:name/get", (Request request) async {
      return Response.send(request.allPathVariables);
    });
  });

  sirius.start(
    callback: (server) {
      print("server is running");
    },
  );

  fileWatcher("example/example.dart", callback: () {
    sirius.close();
  });
}

class Logger extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    print(request.method);
    return Response.next();
  }
}
