import 'dart:convert';
import 'dart:io';

import 'constants.dart';
import 'request.dart';
import 'response.dart';

class Handler {
  final Map<
      String,
      Map<
          String,
          (
            List<
                Future<Response> Function(
                    Request request, Future<Response> Function() nextHandler)>,
            List<Future<Response> Function(Request request)>
          )>> _mainRoutes = {};

  final Map<String, void Function(WebSocket socket)> _mainSocketRoutes = {};

  void registerRoutes(
      Map<
              String,
              Map<
                  String,
                  (
                    List<
                        Future<Response> Function(Request request,
                            Future<Response> Function() nextHandler)>,
                    List<Future<Response> Function(Request request)>
                  )>>
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
    Map<String, String> pathVariables = {};

    if (_mainRoutes[method] == null) {
      _sendErrorResponse(request, HttpStatus.notFound, "Path not found");
      return;
    }

    List<Future<Response> Function(Request request)>? middlewareHandlerList =
        _mainRoutes[method]![uriPath]?.$2;

    List<
            Future<Response> Function(
                Request request, Future<Response> Function() nextHandler)>
        wrapperList = _mainRoutes[method]![uriPath]?.$1 ?? [];

    if (middlewareHandlerList == null) {
      final routeEntries = _mainRoutes[method];

      if (routeEntries != null) {
        for (var val in routeEntries.entries) {
          Map<String, String>? matches = _matchRoute(val.key, uriPath);
          if (matches != null) {
            wrapperList = val.value.$1;
            middlewareHandlerList = val.value.$2;
            pathVariables = matches;
            break;
          }
        }
      }

      if (middlewareHandlerList == null) {
        _sendErrorResponse(request, HttpStatus.notFound, "Path not found");
        return;
      }
    }

    if ([POST, PUT, DELETE].contains(method)) {
      jsonBody = await _getJsonBody(request);
    }

    Request newRequest = Request(request, pathVariables, jsonBody);

    try {
      Response response;

      // creating chain for wrapper middleware
      if (wrapperList.isNotEmpty) {
        Future<Response> Function() composed = wrapperList.reversed
            .fold<Future<Response> Function()>(
                () => _executeHandlerAndMiddleware(
                    newRequest, middlewareHandlerList!), (next, wrapper) {
          return () => wrapper(newRequest, next);
        });

        response = await composed();
      } else {
        // execute without wrapper middleware (loop middleware and handler will executed)
        response = await _executeHandlerAndMiddleware(
            newRequest, middlewareHandlerList);
      }

      _sendSuccessResponse(request, response);
    } catch (e) {
      _sendErrorResponse(request, HttpStatus.internalServerError, e.toString());
    }
    // ---------------------------------
  }

  Future<Response> _executeHandlerAndMiddleware(
      Request request,
      List<Future<Response> Function(Request request)>
          middlewareHandlerList) async {
    for (final handler in middlewareHandlerList) {
      final response = await handler(request);

      if (response.passedData != null) {
        request.passData = response.passedData;
      }

      if (response.isNext == true) {
        continue;
      }

      return response;
    }

    throw Exception(
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
