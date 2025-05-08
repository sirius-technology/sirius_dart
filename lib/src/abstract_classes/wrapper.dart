import 'package:sirius_backend/sirius_backend.dart';

abstract class Wrapper {
  Future<Response> handle(
      Request request, Future<Response> Function() nextHandler);
}
