import 'package:sirius_backend/sirius.dart';

abstract class Middleware {
  Future<Response> handle(Request request);
}
