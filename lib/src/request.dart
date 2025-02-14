import 'dart:io';

class Request {
  final HttpRequest _request;
  final Map<String, String> _pathVariables;
  final Map<String, dynamic>? _body;

  Request(this._request, this._pathVariables, this._body);

  /// Get all path variables
  Map<String, String> get allPathVariables => _pathVariables;

  /// Get a specific path variable by key
  String? pathVariable(String key) => _pathVariables[key];

  /// Get all query parameters
  Map<String, String> get allQueryParams => _request.uri.queryParameters;

  /// Get a specific query parameter by key
  String? queryParam(String key) => allQueryParams[key];

  /// Get JSON body as Map<String, dynamic>?
  Map<String, dynamic>? get jsonBody => _body;

  /// Get a specific value from key in JSON body
  dynamic jsonValue(String key) => _body?[key];
}
