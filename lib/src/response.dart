import 'dart:io';

class Response {
  Map<String, dynamic>? data;
  late int statusCode = HttpStatus.ok;
  bool isNext = false;

  Response status(int statusCode) {
    this.statusCode = statusCode;
    return this;
  }

  Response send(Map<String, dynamic>? data) {
    this.data = data;
    return this;
  }

  Response next() {
    isNext = true;
    return this;
  }
}
