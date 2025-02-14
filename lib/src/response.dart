import 'dart:io';

class Response {
  late Map<String, dynamic> data;
  late int statusCode;

  Response(this.data, {this.statusCode = HttpStatus.ok});
}
