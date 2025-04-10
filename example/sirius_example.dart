import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius sirius = Sirius();

  sirius.post("test", (Request request) async {
    Map<String, ValidationRules> rules = {
      "address": ValidationRules(
          dataType: dataType(DataTypes.NUMBER),
          nullable: false,
          required: required())
    };

    Validator validator = Validator(request.getAllFields(), rules);

    if (!validator.validate()) {
      return Response.send(validator.getAllErrors);
    }

    return Response.send("Success..!");
  });

  sirius.start(
    callback: (server) {
      print("server is running");
    },
  );
}
