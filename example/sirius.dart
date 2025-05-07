import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  app.post("/", (Request request) async {
    // Validator validator = Validator(request.getAllFields(),
    //     {"name": ValidationRules(defaultValue: "this is defalut value")});

    // if (!validator.validate()) {
    //   return Response.send(validator.getError.toString());
    // }
    return Response.sendJson({"name": "SOMESH"},
        headers: {"Content-Type": "text/plain"});
  });

  app.start(callback: (server) {
    print("server is running");
  });

  fileWatcher("example/sirius.dart", callback: () async {
    await app.close();
  });
}
