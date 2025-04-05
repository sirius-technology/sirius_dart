import 'dart:io';

class Response {
  dynamic data;
  int statusCode = HttpStatus.ok;
  bool isNext = false;

  Response(this.data, this.statusCode, {this.isNext = false});

  static Response send(dynamic data, {int status = HttpStatus.ok}) {
    return Response(data, status);
  }

  static Response next() {
    return Response(null, HttpStatus.ok, isNext: true);
  }
}
