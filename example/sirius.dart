import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  Validator.enableTypeSafety = false;

  app.post("/", (Request request) async {
    Validator validator = Validator(request.getJsonBody, {
      "email": ValidationRules(required: required(), validEmail: validEmail())
    });

    if (!validator.validate(typeSafety: true)) {
      return Response.sendJson(validator.getError.value);
    }
    return Response();
  });

  app.post("/valid", (Request request) async {
    Validator validator = Validator(request.getJsonBody, {
      "email": ValidationRules(required: required(), validEmail: validEmail())
    });

    if (!validator.validate()) {
      return Response.sendJson(validator.getError.value);
    }
    return Response();
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
