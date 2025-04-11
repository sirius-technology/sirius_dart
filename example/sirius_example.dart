// import 'package:sirius_backend/sirius_backend.dart';

// void main() {
//   Sirius sirius = Sirius();

//   sirius.post("test", (Request request) async {
//     return Response.send("Success..!");
//   });

//   sirius.useBefore(Middle());
//   sirius.useBefore(Middle2());

//   sirius.post("test1", (Request request) async {
//     return Response.send(request.receiveData);
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

// class Middle extends Middleware {
//   @override
//   Future<Response> handle(Request request) async {
//     print("middleware");

//     return Response.next(passData: "passing");
//   }
// }

// class Middle2 extends Middleware {
//   @override
//   Future<Response> handle(Request request) async {
//     print("middleware");

//     return Response.next(passData: "TT");
//   }
// }
