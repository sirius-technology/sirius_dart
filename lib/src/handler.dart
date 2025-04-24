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
      _sendErrorResponse(request, HttpStatus.internalServerError, e.toString());
    });
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    final String uriPath = request.uri.path;
    final String method = request.method;
    Map<String, dynamic>? jsonBody;
    List<Future<Response> Function(Request r)>? middlewareHandlerList;

    middlewareHandlerList = _mainRoutes[method]?[uriPath];

    if (middlewareHandlerList == null) {
      _sendErrorResponse(request, HttpStatus.notFound, "Path not found");
      return;
    }

    if ([POST, PUT, DELETE].contains(method)) {
      jsonBody = await _getJsonBody(request);
    }

    // handling developers functions
    try {
      Request newRequest = Request(request, {}, jsonBody);

      for (final handler in middlewareHandlerList) {
        final response = await handler(newRequest);

        if (response.passedData != null) {
          newRequest.passData = response.passedData;
        }

        if (response.isNext == true) {
          continue;
        }

        _sendSuccessResponse(request, response);
        return;
      }
    } catch (e) {
      _sendErrorResponse(request, HttpStatus.internalServerError, e.toString());
    }
    // ---------------------------------

    _sendErrorResponse(request, HttpStatus.internalServerError,
        "No response sent by handler. not getting response in handler");
  }

  void _sendSuccessResponse(HttpRequest request, Response response) {
    if (response.overrideHeaders != null) {
      response.overrideHeaders!(request.response.headers);
    } else {
      response.headers?.forEach((key, value) {
        request.response.headers.set(key, value);
      });
    }

    request.response
      ..statusCode = response.statusCode
      ..write(jsonEncode(
        response.data,
        toEncodable: (nonEncodable) => nonEncodable is DateTime
            ? nonEncodable.toIso8601String()
            : nonEncodable.toString(),
      ))
      ..close();
  }

  void _sendErrorResponse(HttpRequest request, int code, String message) {
    request.response
      ..statusCode = code
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({"status": false, "message": message}))
      ..close();
  }

  Future<Map<String, dynamic>?> _getJsonBody(HttpRequest request) async {
    if (request.headers.contentType?.mimeType == "application/json") {
      final content = await utf8.decoder.bind(request).join();
      return jsonDecode(content);
    }
    return null;
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
