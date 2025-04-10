// import 'package:sirius_backend/sirius_backend.dart';

// void main() {
//   Sirius sirius = Sirius();

//   sirius.post("api/partner/register", (Request request) async {
//     Map<String, ValidationRules> rules = {
//       "kitchen_type": ValidationRules(
//           required: required(),
//           inList: inList(["HOME_KITCHEN", "COMMERCIAL_KITCHEN"]))
//     };

//     Validator validator = Validator(request, rules);

//     if (!validator.validate()) {
//       return Response.send(validator.getError.value);
//     }

//     return Response.send("Success..!");
//   });

//   sirius.start(
//     callback: (server) {
//       print("server is running");
//     },
//   );
// }
