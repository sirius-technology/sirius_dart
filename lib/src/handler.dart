import 'dart:convert';
import 'dart:io';
import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/helpers/parse_stack_trace.dart';
import 'constants.dart';

typedef WrapperFunction = Future<Response> Function(
    Request request, Future<Response> Function() nextHandler);

typedef HttpHandlerFunction = Future<Response> Function(Request request);

typedef SocketHandlerFunction = void Function(
    Request request, SocketConnection webSocket);

class Handler {
  final Map<String,
          Map<String, (List<WrapperFunction>, List<HttpHandlerFunction>)>>
      _mainRoutes = {};

  final Map<String, SocketHandlerFunction> _mainSocketRoutes = {};

  void registerRoutes(
      Map<String,
              Map<String, (List<WrapperFunction>, List<HttpHandlerFunction>)>>
          routesMap,
      Map<String, SocketHandlerFunction> socketRoutesMap) {
    _mainRoutes.addAll(routesMap);
    _mainSocketRoutes.addAll(socketRoutesMap);
  }

  void handleRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      _handleSocketRequest(request);
    } else {
      _handleHttpRequest(request);
    }
  }

  void _handleSocketRequest(HttpRequest request) {
    final uriPath = request.uri.path;
    Map<String, String> pathVariables = {};
    void Function(Request request, SocketConnection webSocket)? handler =
        _mainSocketRoutes[uriPath];

    if (handler == null) {
      for (var val in _mainSocketRoutes.entries) {
        Map<String, String>? matches = _matchRoute(val.key, uriPath);
        if (matches != null) {
          handler = val.value;
          pathVariables = matches;
          break;
        }
      }

      if (handler == null) {
        _sendErrorResponse(
            request, HttpStatus.notFound, "Path not found", null);
        return;
      }
    }

    WebSocketTransformer.upgrade(request).then((WebSocket webSocket) async {
      Request webSocketRequest = Request(request, pathVariables, null);

      handler!(webSocketRequest, SocketConnection(webSocket));
    }).catchError((err, stackTrace) {
      _sendErrorResponse(
          request, HttpStatus.internalServerError, err.toString(), stackTrace);
    });
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    final String uriPath = request.uri.path;
    final String method = request.method;
    Map<String, dynamic>? jsonBody;
    Map<String, String> pathVariables = {};

    if (_mainRoutes[method] == null) {
      _sendErrorResponse(request, HttpStatus.notFound, "Path not found", null);
      return;
    }

    List<HttpHandlerFunction>? middlewareHandlerList =
        _mainRoutes[method]![uriPath]?.$2;

    List<WrapperFunction> wrapperList = _mainRoutes[method]![uriPath]?.$1 ?? [];

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
        _sendErrorResponse(
            request, HttpStatus.notFound, "Path not found", null);
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
    } catch (e, stackTrace) {
      _sendErrorResponse(
          request, HttpStatus.internalServerError, e.toString(), stackTrace);
    }
    // ---------------------------------
  }

  Future<Response> _executeHandlerAndMiddleware(
      Request request, List<HttpHandlerFunction> middlewareHandlerList) async {
    for (HttpHandlerFunction handler in middlewareHandlerList) {
      Response response = await handler(request);

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
      response.headers.forEach((key, value) {
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

  void _sendErrorResponse(
      HttpRequest request, int code, String message, StackTrace? stackTrace) {
    Map<String, dynamic> errorResponse = {
      "status": false,
      "code": code,
      "message": message,
    };

    if (stackTrace != null) {
      List<Map<String, dynamic>>? structreTrace = parseStackTrace(stackTrace);
      Map<String, dynamic> traceResponse = {
        "file": structreTrace?.elementAt(0)["file"],
        "line": structreTrace?.elementAt(0)["line"],
        "trace": structreTrace,
      };
      errorResponse.addAll(traceResponse);
    }

    request.response
      ..statusCode = code
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(errorResponse))
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
