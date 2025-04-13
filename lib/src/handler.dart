import 'dart:convert';
import 'dart:io';

import 'constants.dart';
import 'request.dart';
import 'response.dart';

class Handler {
  final Map<String, Map<String, List<Future<Response> Function(Request r)>>>
      _mainRoutes = {};
  final Map<String, void Function(WebSocket socket)> _mainSocketRoutes = {};

  void registerRoutes(
      Map<String, Map<String, List<Future<Response> Function(Request r)>>>
          routesMap,
      Map<String, void Function(WebSocket socket)> socketRoutesMap) {
    _mainRoutes.addAll(routesMap);
    _mainSocketRoutes.addAll(socketRoutesMap);
  }

  void handleRequest(HttpRequest request) {
    if (_mainSocketRoutes.containsKey(request.uri.path) &&
        WebSocketTransformer.isUpgradeRequest(request)) {
      _handleSocketRequest(request);
    } else {
      _handleHttpRequest(request);
    }
  }

  void _handleSocketRequest(HttpRequest request) {
    WebSocketTransformer.upgrade(request).then((WebSocket socket) {
      // calling websocket functions
      _mainSocketRoutes[request.uri.path]!(socket);
    }).catchError((e) {
      request.response
        ..statusCode = HttpStatus.internalServerError
        ..headers.contentType = ContentType.json
        ..write(_errorResponseData(e.toString()))
        ..close();
    });
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
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
    } else {
      throw Exception(
          "Unsupported HTTP method '$method' or missing 'application/json' content type for JSON request.");
    }

    for (MapEntry<String,
            Map<String, List<Future<Response> Function(Request r)>>> val
        in _mainRoutes.entries) {
      final String routePath = val.key;
      final List<Future<Response> Function(Request r)>? middelwareHandlerList =
          val.value[method];

      final Map<String, String>? match = _matchRoute(routePath, uriPath);

      if (match != null && middelwareHandlerList != null) {
        try {
          Request newRequest = Request(request, match, jsonBody);

          for (Future<Response> Function(Request r) value
              in middelwareHandlerList) {
            Response response = await value(newRequest);

            if (response.passedData != null) {
              newRequest.passData = response.passedData;
            }

            if (response.isNext == true) {
              continue;
            } else {
              request.response
                ..statusCode = response.statusCode
                ..headers.contentType = ContentType.json
                ..write(jsonEncode(
                  response.data,
                  // for handling object jsons conversion
                  toEncodable: (nonEncodable) {
                    if (nonEncodable is DateTime) {
                      return nonEncodable.toIso8601String();
                    }
                    return nonEncodable.toString();
                  },
                ))
                ..close();
              break;
            }
          }
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
