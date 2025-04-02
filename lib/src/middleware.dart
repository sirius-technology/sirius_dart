import 'package:sirius_backend/sirius_backend.dart';

abstract class Middleware {
  Future<Response> handle(Request request);
}
