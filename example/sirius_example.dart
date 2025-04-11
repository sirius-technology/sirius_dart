// import 'package:sirius_backend/sirius_backend.dart';

// void main() {
//   Sirius sirius = Sirius();

//   sirius.post("test", (Request request) async {
//     Map<String, ValidationRules> rules = {
//       "fruits": ValidationRules(
//           required: required(),
//           dataType: dataType(DataTypes.LIST),
//           childList: [
//             ValidationRules(required: required(), exactLength: exactLength(3)),
//             ValidationRules(
//                 required: required(),
//                 dataType: dataType(DataTypes.MAP),
//                 childMap: {
//                   "add": ValidationRules(required: required()),
//                   "plus": ValidationRules(
//                       required: required(),
//                       nullable: true,
//                       exactNumber: exactNumber(2)),
//                 })
//           ])
//     };

//     Validator validator = Validator(request.getAllFields(), rules);

//     if (!validator.validate()) {
//       return Response.send(validator.getAllErrors);
//     }

//     return Response.send("Success..!");
//   });

//   sirius.start(
//     callback: (server) {
//       print("server is running");
//     },
//   );

//   fileWatcher("example/sirius_example.dart", callback: () {
//     sirius.close();
//   });
// }
