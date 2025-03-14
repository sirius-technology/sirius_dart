import 'package:sirius/sirius.dart';
import 'package:sirius/src/middleware.dart';

class FirstMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    print("First middleware --->>> ");

    return Response().next();
    // return Response().next();
  }
}
