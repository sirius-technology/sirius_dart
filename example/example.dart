import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/wrapper.dart';

void main() {
  Sirius sirius = Sirius();

  sirius.wrap(Wrapper1());

  sirius.post("test", (Request request) async {
    return Response.send(request.jsonBody);
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

class Wrapper1 extends Wrapper {
  @override
  Future<Response> handle(
      Request request, Future<Response> Function() nextHandler) async {
    print("Wrapper 1 Start");
    return Response.send("fff");

    Response res = await nextHandler();

    print("Wrapper 1 End");

    return res;
  }
}
