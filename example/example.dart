// import 'package:sirius_backend/sirius_backend.dart';

// void main() {
//   Sirius sirius = Sirius();

//   // sirius.useBefore(Middleware1());
//   // sirius.wrap(Wrapper1());
//   // sirius.wrap(Wrapper2());

//   sirius.get("user", handler1);

//   sirius.group("api", (route) {
//     route.get("driver", handler2);
//   });

//   ///
//   ///
//   ///
//   ///
//   ///
//   ///
//   ///
//   ///
//   sirius.start(
//     callback: (server) {
//       print("server is running");
//     },
//   );

//   fileWatcher("example/example.dart", callback: () {
//     sirius.close();
//   });
// }

// // /// wrapper
// // class Wrapper1 extends Wrapper {
// //   @override
// //   Future<Response> handle(
// //       Request request, Future<Response> Function() nextHandler) async {
// //     print("Wrapper 1 Start");
// //     Response res = await nextHandler();
// //     print("Wrapper 1 End");
// //     return res;
// //   }
// // }

// // class Wrapper2 extends Wrapper {
// //   @override
// //   Future<Response> handle(
// //       Request request, Future<Response> Function() nextHandler) async {
// //     print("Wrapper 2 Start");
// //     Response res = await nextHandler();
// //     print("Wrapper 2 End");
// //     return res;
// //   }
// // }

// // /// Middleware
// // class Middleware1 extends Middleware {
// //   @override
// //   Future<Response> handle(Request request) async {
// //     print("middleware 1");

// //     return Response.next();
// //   }
// // }

// /// handlers

// Future<Response> handler1(Request request) async {
//   print("handler 1");
//   return Response.send("handler 1");
// }

// Future<Response> handler2(Request request) async {
//   print("handler 2");
//   return Response.send("handler 2");
// }
