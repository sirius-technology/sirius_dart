import 'package:sirius/sirius.dart';
import 'package:sirius/src/validation_rules.dart';
import 'package:sirius/src/validator.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.post("api", (Request request) async {
    Map<String, ValidationRules> rules = {
      "name": ValidationRules(),
      "age": ValidationRules(),
      "email": ValidationRules(),
    };

    Validator validator = Validator(request, rules);

    if (!validator.validate()) {
      return Response().send({});
    }

    return Response().send(request.jsonBody);
  });

  app.start(
    port: 9000,
    callback: (server) {
      print("Server is running");
    },
  );

  await fileWatcher("example/sirius_example.dart", callback: () {
    app.close();
  });
}
