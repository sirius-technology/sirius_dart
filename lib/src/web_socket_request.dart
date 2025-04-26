import 'dart:io';

/// Represents an incoming WebSocket upgrade request in Sirius.
///
/// Provides easy access to request metadata such as headers,
/// query parameters, and extracted path variables.
///
/// Also supports passing custom data between middlewares and handlers.
///
/// ### Example:
/// ```dart
/// sirius.webSocket('/chat/:roomId', (req, socket) {
///   final roomId = req.pathVariable('roomId');
///   final authToken = req.queryParam('token');
///   final userAgent = req.headerValue('user-agent');
/// });
/// ```
class WebSocketRequest {
  final HttpRequest _request;
  final Map<String, String> _pathVariables;
  final Map<String, String> _headers = {};

  dynamic _passedData;

  /// Creates a [WebSocketRequest] from an [HttpRequest] and matched [pathVariables].
  WebSocketRequest(this._request, this._pathVariables) {
    _request.headers.forEach((key, values) {
      _headers[key.toLowerCase()] = values.join(', ');
    });
  }

  /// Returns all extracted path variables from the route.
  ///
  /// Example:
  /// `/chat/:roomId` -> `{'roomId': '123'}`
  Map<String, String> get allPathVariables => _pathVariables;

  /// Returns a specific path variable by [key].
  ///
  /// Example:
  /// ```dart
  /// final id = req.pathVariable('roomId');
  /// ```
  String? pathVariable(String key) => _pathVariables[key];

  /// Returns all query parameters from the WebSocket request URL.
  ///
  /// Example:
  /// `/chat?token=abc123`
  Map<String, String> get allQueryParams => _request.uri.queryParameters;

  /// Returns a specific query parameter by [key].
  ///
  /// Example:
  /// ```dart
  /// final token = req.queryParam('token');
  /// ```
  String? queryParam(String key) => allQueryParams[key];

  /// Returns all request headers as a case-insensitive map.
  Map<String, String> get headers => _headers;

  /// Returns a specific request header value by [key].
  ///
  /// Example:
  /// ```dart
  /// final userAgent = req.headerValue('user-agent');
  /// ```
  String? headerValue(String key) => _headers[key.toLowerCase()];

  /// Passes data from a middleware or handler to later handlers.
  ///
  /// Useful for authentication, user info, etc.
  set passData(dynamic data) {
    _passedData = data;
  }

  /// Retrieves data passed between handlers using [passData].
  dynamic get receiveData => _passedData;

  /// Returns the HTTP method used in the WebSocket upgrade request.
  ///
  /// (Generally "GET" in WebSocket handshakes.)
  String get method => _request.method;

  /// Returns the original underlying [HttpRequest] object.
  HttpRequest get httpRequest => _request;

  /// Merges and returns all available fields (path variables + query params).
  ///
  /// Useful for validation or unified parameter access.
  ///
  /// Query parameters take precedence over path variables.
  Map<String, dynamic> getAllFields() {
    return {
      ..._pathVariables, // lower priority
      ...allQueryParams, // higher priority
    };
  }
}
