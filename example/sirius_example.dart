// import 'package:sirius_backend/sirius_backend.dart';

// Future<void> main() async {
//   Sirius app = Sirius();

//   app.post("api", (Request request) async {
//     print("1 object");
//     return Response.next();
//   }, useAfter: [AppMiddleware()]);

//   app.start(
//     port: 1234,
//     callback: (server) {
//       print("Server is running");
//     },
//   );

//   await fileWatcher("example/sirius_example.dart", callback: () {
//     app.close();
//   });
// }

// class AppMiddleware extends Middleware {
//   @override
//   Future<Response> handle(Request request) async {
//     print("object");
//     return Response.send(null);
//   }
// }
