import 'dart:convert';
import 'dart:io';
import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/helpers/logging.dart';
import 'package:sirius_backend/src/helpers/parse_stack_trace.dart';
import 'constants.dart';

typedef WrapperFunction = Future<Response> Function(
    Request request, Future<Response> Function() nextHandler);

typedef HttpHandlerFunction = Future<Response> Function(Request request);

typedef SocketHandlerFunction = void Function(
    Request request, SocketConnection webSocket);

typedef ExceptionHandlerFunction = Future<Response> Function(Request request,
    Response response, int statusCode, Object exception, StackTrace stackTrace);

class Handler {
  final Map<String,
          Map<String, (List<WrapperFunction>, List<HttpHandlerFunction>)>>
      _mainRoutes = {};

  final Map<String, SocketHandlerFunction> _mainSocketRoutes = {};

  ExceptionHandlerFunction? _exceptionHandler;

  void registerRoutes(
      Map<String,
              Map<String, (List<WrapperFunction>, List<HttpHandlerFunction>)>>
          routesMap,
      Map<String, SocketHandlerFunction> socketRoutesMap,
      ExceptionHandlerFunction? exceptionHandler) {
    _mainRoutes.addAll(routesMap);
    _mainSocketRoutes.addAll(socketRoutesMap);

    _exceptionHandler = exceptionHandler;
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
            Request(request, pathVariables, null),
            HttpStatus.notFound,
            Exception("Path not found"),
            StackTrace.current);
        return;
      }
    }

    Request webSocketRequest = Request(request, pathVariables, null);

    WebSocketTransformer.upgrade(request).then((WebSocket webSocket) async {
      handler!(webSocketRequest, SocketConnection(webSocket));
    }).catchError((err, stackTrace) {
      _sendErrorResponse(
          webSocketRequest, HttpStatus.internalServerError, err, stackTrace);
    });
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    final String uriPath = request.uri.path;
    final String method = request.method;
    Map<String, dynamic>? body;
    Map<String, String> pathVariables = {};

    if (_mainRoutes[method] == null) {
      _sendErrorResponse(Request(request, {}, body), HttpStatus.notFound,
          Exception("Path not found"), StackTrace.current);
      return;
    }

    if ([POST, PUT, PATCH, DELETE].contains(method)) {
      try {
        body = await _getBody(request);
      } catch (err, stackTrace) {
        _sendErrorResponse(Request(request, {}, null), 400, err, stackTrace);
        return;
      }
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
            Request(request, pathVariables, body),
            HttpStatus.notFound,
            Exception("Path not found"),
            StackTrace.current);
        return;
      }
    }

    Request newRequest = Request(request, pathVariables, body);

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
    } catch (err, stackTrace) {
      _sendErrorResponse(
          newRequest, HttpStatus.internalServerError, err, stackTrace);
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

  void _sendErrorResponse(Request request, int statusCode, Object exception,
      StackTrace stackTrace) async {
    List<Map<String, dynamic>>? structureTrace = parseStackTrace(stackTrace);

    Map<String, dynamic> errorResponseData = {
      "status": false,
      "code": statusCode,
      "message": exception.toString(),
      "file": structureTrace?.elementAt(0)["file"],
      "line": structureTrace?.elementAt(0)["line"],
      "trace": structureTrace
    };

    Response response = Response.sendJson(
      errorResponseData,
      statusCode: statusCode,
    );

    if (_exceptionHandler != null) {
      response = await _exceptionHandler!
          .call(request, response, statusCode, exception, stackTrace);
    }

    request.rawHttpRequest.response
      ..statusCode = response.statusCode
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(
        response.data,
        toEncodable: (nonEncodable) => nonEncodable is DateTime
            ? nonEncodable.toIso8601String()
            : nonEncodable.toString(),
      ))
      ..close();
  }

  Future<Map<String, dynamic>?> _getBody(HttpRequest request) async {
    final String? mimeType = request.headers.contentType?.mimeType;
    final String content = await utf8.decoder.bind(request).join();

    if (content.trim().isEmpty) {
      return null;
    }

    if (mimeType == 'application/json') {
      return jsonDecode(content);
    } else if (mimeType == 'application/x-www-form-urlencoded') {
      return Uri.splitQueryString(content);
    } else if (mimeType == 'multipart/form-data') {
      logWarning("Multipart form-data coming soon...");
    } else {
      throw Exception("Unsupported Content-Type: $mimeType");
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
