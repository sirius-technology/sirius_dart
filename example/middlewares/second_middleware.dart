import 'package:sirius/src/middleware.dart';
import 'package:sirius/src/request.dart';
import 'package:sirius/src/response.dart';

class SecondMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    return Response().next();
  }
}
