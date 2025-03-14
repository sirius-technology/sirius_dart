import 'dart:convert';
import 'dart:io';

import 'package:sirius/src/middleware.dart';

import 'constants.dart';
import 'request.dart';
import 'response.dart';

class Router {
  final Map<String, Map<String, Future<Response> Function(Request r)>>
      _mainRoutes = {};

  final List<Middleware> _mainMiddlewares = [];

  void registerRoutes(
      Map<String, Map<String, Future<Response> Function(Request r)>>
          routesMap) {
    _mainRoutes.addAll(routesMap);
  }

  void registerMiddlewares(List<Middleware> middlewaresList) {
    _mainMiddlewares.addAll(middlewaresList);
  }

  Future<void> handleRequest(HttpRequest request) async {
    final String uriPath = request.uri.path;
    final String method = request.method;

    final List<String> jsonReqMethods = [POST, PUT, DELETE];

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
        in _mainRoutes.entries) {
      final String routePath = val.key;
      final Future<Response> Function(Request r)? handler = val.value[method];

      final Map<String, String>? match = _matchRoute(routePath, uriPath);

      if (match != null && handler != null) {
        try {
          // middleware handler
          for (Middleware val in _mainMiddlewares) {
            Response middlewareRes =
                await val.handle(Request(request, match, jsonBody));

            if (middlewareRes.isNext == false) {
              request.response
                ..statusCode = middlewareRes.statusCode
                ..headers.contentType = ContentType.json
                ..write(jsonEncode(middlewareRes.data))
                ..close();
              return;
            }
          }

          // request handler
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
