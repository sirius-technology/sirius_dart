import 'dart:io';
import 'dart:convert';
import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/helpers/formatting.dart';
import 'package:sirius_backend/src/helpers/logging.dart';
import '../constants/constant_methods.dart';

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
            Request(request, pathVariables,
                (<String, dynamic>{}, <String, File>{})),
            HttpStatus.notFound,
            Exception("Path not found"),
            StackTrace.current);
        return;
      }
    }

    Request webSocketRequest = Request(
        request, pathVariables, (<String, dynamic>{}, <String, File>{}));

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
    (Map<String, dynamic>, Map<String, dynamic>)? body;
    Map<String, String> pathVariables = {};

    if (_mainRoutes[method] == null) {
      _sendErrorResponse(Request(request, {}, null), HttpStatus.notFound,
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

      _sendSuccessResponse(newRequest, response);
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

  void _sendSuccessResponse(Request request, Response response) {
    HttpRequest rawRequest = request.rawHttpRequest;

    if (response.overrideHeaders != null) {
      response.overrideHeaders!(rawRequest.response.headers);
    } else {
      response.headers.forEach((key, value) {
        rawRequest.response.headers.set(key, value);
      });
    }

    rawRequest.response
      ..statusCode = response.statusCode
      ..write(jsonEncode(
        response.data,
        toEncodable: (nonEncodable) => nonEncodable is DateTime
            ? nonEncodable.toIso8601String()
            : nonEncodable.toString(),
      ))
      ..close();

    _cleanupTempFiles(request);
  }

  void _sendErrorResponse(Request request, int statusCode, Object exception,
      StackTrace stackTrace) async {
    List<Map<String, dynamic>>? structureTrace = formatStackTrace(stackTrace);

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

    _cleanupTempFiles(request);
  }

  Future<(Map<String, dynamic>, Map<String, dynamic>)?> _getBody(
      HttpRequest request) async {
    final contentType = request.headers.contentType;
    final mimeType = contentType?.mimeType;

    if (mimeType == null) {
      return null;
    }

    if (mimeType == 'application/json') {
      final content = await utf8.decoder.bind(request).join();
      if (content.trim().isEmpty) {
        return (<String, dynamic>{}, <String, dynamic>{});
      }

      return (jsonDecode(content) as Map<String, dynamic>, <String, dynamic>{});
    }

    if (mimeType == 'application/x-www-form-urlencoded') {
      final content = await utf8.decoder.bind(request).join();
      if (content.trim().isEmpty) {
        return (<String, dynamic>{}, <String, dynamic>{});
      }
      ;
      return (Uri.splitQueryString(content), <String, dynamic>{});
    }

    if (mimeType == 'text/plain') {
      final content = await utf8.decoder.bind(request).join();
      if (content.trim().isEmpty) {
        return (<String, dynamic>{}, <String, dynamic>{});
      }

      return ({'text': content}, <String, dynamic>{});
    }

    if (mimeType == 'multipart/form-data') {
      return parseMultipartFormData(request);
    }

    throw Exception("Unsupported Content-Type: $mimeType");
  }

  Future<(Map<String, dynamic>, Map<String, dynamic>)> parseMultipartFormData(
      HttpRequest request) async {
    final contentType = request.headers.contentType;
    final boundary = contentType?.parameters['boundary'];

    if (boundary == null) {
      throw Exception('Missing boundary');
    }

    final delimiter = utf8.encode('--$boundary');
    final bodyBytes = await request.fold<List<int>>([], (b, d) => b..addAll(d));

    final int length = bodyBytes.length;
    int start = 0;

    final fields = <String, dynamic>{};
    final files = <String, dynamic>{};

    while (start < length) {
      final boundaryIndex = _indexOf(bodyBytes, delimiter, start);
      if (boundaryIndex == -1) break;

      start = boundaryIndex + delimiter.length;

      // End of body
      if (start < length &&
          bodyBytes[start] == 45 &&
          bodyBytes[start + 1] == 45) {
        break;
      }

      // Skip CRLF
      if (bodyBytes[start] == 13 && bodyBytes[start + 1] == 10) {
        start += 2;
      }

      final nextBoundaryIndex = _indexOf(bodyBytes, delimiter, start);
      final partEnd = nextBoundaryIndex != -1 ? nextBoundaryIndex - 2 : length;

      final partBytes = bodyBytes.sublist(start, partEnd);

      final headerEnd = _indexOf(partBytes, utf8.encode('\r\n\r\n'), 0);
      if (headerEnd == -1) continue;

      final headersRaw = utf8.decode(partBytes.sublist(0, headerEnd));
      final content = partBytes.sublist(headerEnd + 4);

      final headers = <String, String>{};
      for (var line in headersRaw.split('\r\n')) {
        final index = line.indexOf(':');
        if (index == -1) continue;
        final key = line.substring(0, index).trim().toLowerCase();
        final value = line.substring(index + 1).trim();
        headers[key] = value;
      }

      final disposition = headers['content-disposition'];
      if (disposition == null) continue;

      final nameMatch = RegExp(r'name="([^"]+)"').firstMatch(disposition);
      if (nameMatch == null) continue;

      final name = nameMatch.group(1)!;
      final filenameMatch =
          RegExp(r'filename="([^"]+)"').firstMatch(disposition);

      if (filenameMatch != null) {
        final filename = filenameMatch.group(1)!;

        // Store file metadata only (no saving)
        files[name] = {
          'fileName': filename,
          'size': content.length,
          'content': content, // raw bytes
        };
      } else {
        final value = utf8.decode(content);
        fields[name] = value;
      }

      start = partEnd + 2;
    }

    return (fields, files);
  }

  int _indexOf(List<int> data, List<int> pattern, int start) {
    for (int i = start; i <= data.length - pattern.length; i++) {
      bool found = true;
      for (int j = 0; j < pattern.length; j++) {
        if (data[i + j] != pattern[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
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

  void _cleanupTempFiles(Request request) {
    if (request.tempFilePathList == null) {
      return;
    }
    for (final path in request.tempFilePathList!) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (err) {
          logError(err.toString());
        }
      }
    }
  }
}
