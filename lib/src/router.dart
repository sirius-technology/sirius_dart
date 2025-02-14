import 'dart:convert';
import 'dart:io';

import 'constants.dart';
import 'request.dart';
import 'response.dart';

class Router {
  final Map<String, Map<String, Future<Response> Function(Request r)>> _routes =
      {};

  void register(String method, String path,
      Future<Response> Function(Request r) handler) {
    _routes.putIfAbsent(path, () {
      return {method: handler};
    });
  }

  Future<void> handleRequest(HttpRequest request) async {
    final String uriPath = request.uri.path;
    final String method = request.method;

    final List<String> jsonReqMethods = [POST, PUT];

    Map<String, dynamic>? jsonBody;

    if (jsonReqMethods.contains(method) &&
        request.headers.contentType?.mimeType == "application/json") {
      try {
        String content = await utf8.decoder.bind(request).join();
        jsonBody = jsonDecode(content);
      } catch (e) {
        request.response
          ..statusCode = HttpStatus.badRequest
          ..headers.contentType = ContentType.json
          ..write(_errorResponseData(e.toString()))
          ..close();
        return;
      }
    }

    for (MapEntry<String, Map<String, Future<Response> Function(Request r)>> val
        in _routes.entries) {
      final String routePath = val.key;
      final Future<Response> Function(Request r)? handler = val.value[method];

      final Map<String, String>? match = _matchRoute(routePath, uriPath);

      if (match != null && handler != null) {
        try {
          Response response = await handler(Request(request, match, jsonBody));
          request.response
            ..statusCode = response.statusCode
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(response.data))
            ..close();
          return;
        } catch (e) {
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..headers.contentType = ContentType.json
            ..write(_errorResponseData(e.toString()))
            ..close();
          return;
        }
      }
    }

    request.response
      ..statusCode = HttpStatus.notFound
      ..headers.contentType = ContentType.json
      ..write(_errorResponseData("Page not found"))
      ..close();
    return;
  }

  String _errorResponseData(String msg) {
    return jsonEncode({"status": false, "message": msg});
  }

  Map<String, String>? _matchRoute(String route, String uri) {
    final List<String> routeSeg = route.split("/");
    final List<String> uriSeg = uri.split("/");

    if (routeSeg.length != uriSeg.length) {
      return null;
    }

    Map<String, String> pathVar = {};

    for (int i = 0; i < routeSeg.length; i++) {
      if (routeSeg.elementAt(i).startsWith(":")) {
        pathVar[routeSeg[i].substring(1)] = uriSeg.elementAt(i);
      } else if (routeSeg.elementAt(i) != uriSeg.elementAt(i)) {
        return null;
      }
    }

    return pathVar;
  }
}
