import 'dart:io';

// CHANGE : Change structure of Response Class
//
//
//
class Response {
  dynamic data;
  late int statusCode = HttpStatus.ok;
  bool isNext = false;

  Response status(int statusCode) {
    this.statusCode = statusCode;
    return this;
  }

  Response send(dynamic data) {
    this.data = data;
    return this;
  }

  Response next() {
    isNext = true;
    return this;
  }
}
