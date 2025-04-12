import 'dart:io';

/// Represents an HTTP request wrapper used in the Sirius backend framework.
///
/// Provides utilities to access path variables, query parameters, headers,
/// and JSON request bodies in a convenient way.
///
/// ### Example usage:
/// ```dart
/// void handleRequest(Request req) {
///   final userId = req.pathVariable('id');
///   final search = req.queryParam('search');
///   final name = req.jsonValue('name');
///   final method = req.method;
///   final authHeader = req.headerValue('authorization');
/// }
/// ```
class Request {
  final HttpRequest _request;
  final Map<String, String> _pathVariables;
  final Map<String, dynamic>? _body;
  final Map<String, String> _headers = {};

  dynamic _passedData;

  /// Constructs a [Request] object with an [HttpRequest], path variables, and JSON body.
  ///
  /// Automatically extracts headers into a simplified lowercase map.
  Request(this._request, this._pathVariables, this._body) {
    _request.headers.forEach((key, values) {
      _headers[key.toLowerCase()] = values.join(', ');
    });
  }

  /// Returns all path variables as a map.
  ///
  /// Useful when you want to access all dynamic segments in the route.
  ///
  /// ### Example
  /// ```dart
  /// final vars = request.allPathVariables;
  /// print(vars['userId']);
  /// ```
  Map<String, String> get allPathVariables => _pathVariables;

  /// Returns the value of a specific path variable by [key].
  ///
  /// ### Example
  /// ```dart
  /// final id = request.pathVariable('id');
  /// ```
  String? pathVariable(String key) => _pathVariables[key];

  /// Returns all query parameters as a map.
  ///
  /// ### Example
  /// ```dart
  /// final params = request.allQueryParams;
  /// print(params['search']);
  /// ```
  Map<String, String> get allQueryParams => _request.uri.queryParameters;

  /// Returns the value of a specific query parameter by [key].
  ///
  /// ### Example
  /// ```dart
  /// final keyword = request.queryParam('search');
  /// ```
  String? queryParam(String key) => allQueryParams[key];

  /// Returns the parsed JSON body as a `Map<String, dynamic>?`.
  ///
  /// ### Example
  /// ```dart
  /// final body = request.jsonBody;
  /// print(body?['name']);
  /// ```
  Map<String, dynamic>? get jsonBody => _body;

  /// Returns the value from the JSON body for a given [key].
  ///
  /// ### Example
  /// ```dart
  /// final email = request.jsonValue('email');
  /// ```
  dynamic jsonValue(String key) => _body?[key];

  /// Returns all headers in a lowercase map format.
  ///
  /// ### Example
  /// ```dart
  /// final allHeaders = request.headers;
  /// print(allHeaders['authorization']);
  /// ```
  Map<String, String> get headers => _headers;

  /// Returns the value of the specified header by [key], case-insensitive.
  ///
  /// Useful for extracting values like authorization tokens or content types
  /// from incoming requests.
  ///
  /// ### Example
  /// ```dart
  /// final auth = request.headerValue('Authorization');
  /// ```
  String? headerValue(String key) => _headers[key.toLowerCase()];

  /// Sets custom data to be passed from middleware to subsequent middleware
  /// or handlers during the request lifecycle.
  ///
  /// This is useful for sharing computed values like authentication results,
  /// decoded tokens, or any request-specific metadata.
  ///
  /// ### Example
  /// ```dart
  /// request.passData = {"userId": 42};
  /// ```
  set passData(dynamic data) {
    _passedData = data;
  }

  /// Retrieves data passed earlier in the middleware or handler chain.
  ///
  /// Use this to access custom information stored using [passData].
  ///
  /// ### Example
  /// ```dart
  /// final data = request.receiveData;
  /// final userId = data?['userId'];
  /// ```
  dynamic get receiveData => _passedData;

  /// Returns the HTTP method of the request (e.g., GET, POST).
  ///
  /// ### Example
  /// ```dart
  /// final method = request.method;
  /// if (method == 'POST') {
  ///   // Handle post request
  /// }
  /// ```
  String get method => _request.method;

  /// Returns the original [HttpRequest] object from `dart:io`.
  ///
  /// Useful if you need to access low-level request data directly.
  ///
  /// ### Example
  /// ```dart
  /// final connectionInfo = request.httpRequest.connectionInfo;
  /// ```
  HttpRequest get httpRequest => _request;

  /// Merges and returns all fields from path variables, query parameters,
  /// and JSON body into a single map.
  ///
  /// Priority (in case of key conflicts): JSON body > query params > path variables.
  Map<String, dynamic> getAllFields() {
    return {
      ..._pathVariables, // lowest priority
      ...allQueryParams,
      ...(jsonBody ?? {}), // highest priority
    };
  }
}
