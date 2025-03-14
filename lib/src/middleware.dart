import 'package:sirius/sirius.dart';

abstract class Middleware {
  Future<Response> handle(Request request);
}
