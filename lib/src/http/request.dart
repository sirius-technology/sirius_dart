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
  final (Map<String, dynamic>, Map<String, dynamic>)? _body;
  final Map<String, String> _headers = {};
  List<String>? tempFilePathList;

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

  /// Returns the parsed JSON body as a non-nullable `Map<String, dynamic>`.
  ///
  /// If the body is `null`, returns an empty map instead.
  ///
  /// Useful when you want to avoid null checks while accessing body data.
  ///
  /// ### Example
  /// ```dart
  /// final data = request.getBody;
  /// final name = data['name'];
  /// ```
  Map<String, dynamic> get getBody => _body?.$1 ?? const {};

  /// Indicates whether the request contains a parsed body.
  ///
  /// Returns `true` if the request includes a JSON body or was successfully
  /// parsed into `_body`. Returns `false` when:
  /// - No body was sent with the request, or
  /// - The body could not be parsed as JSON.
  ///
  /// Useful when you need to differentiate between an empty body and an
  /// intentionally empty JSON object `{}`.
  ///
  /// ### Example
  /// ```dart
  /// if (request.hasBody) {
  ///   final data = request.getBody;
  ///   // Handle data
  /// } else {
  ///   // No body provided
  /// }
  /// ```
  bool get hasBody => _body != null;

  /// Returns the value from the JSON body for a given [key].
  ///
  /// ### Example
  /// ```dart
  /// final email = request.getValue('email');
  /// ```
  dynamic getValue(String key) => _body?.$1[key];

  /// Returns the uploaded file as a [File] object for the given [key].
  ///
  /// If the file hasn't been saved to disk yet, it is saved to a temporary
  /// directory and then returned.
  ///
  /// Example:
  /// ```dart
  /// final File? file = request.getFile('profile');
  /// if (file != null) {
  ///   print('Temp path: ${file.path}');
  /// }
  /// ```
  File? getFile(String key) {
    final fileMeta = _body?.$2[key];
    if (fileMeta == null) return null;

    // Already saved to temp?
    if (fileMeta['tempFilePath'] != null) {
      return File(fileMeta['tempFilePath']);
    }

    final content = fileMeta['content'] as List<int>?;
    final filename = fileMeta['fileName'] as String?;

    if (content == null || filename == null) return null;

    // Ensure temp directory exists
    final tempDir = Directory('temp');
    if (!tempDir.existsSync()) {
      tempDir.createSync(recursive: true);
    }

    final safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final tempPath = 'temp/$safeName';

    final tempFile = File(tempPath);
    tempFile.writeAsBytesSync(content);

    // Store path back to map for future access
    fileMeta['tempFilePath'] = tempPath;

    _trackTempFile(tempPath);

    return tempFile;
  }

  /// Returns the metadata of an uploaded file for the given [key] as a `Map<String, dynamic>`.
  ///
  /// This includes:
  /// - `fileName`: The original name of the uploaded file.
  /// - `size`: The size of the file in bytes.
  /// - `content`: The raw bytes of the file (as `List<int>`).
  /// - `tempFilePath`: Path to the temp file if it has been saved (optional).
  ///
  /// Returns `null` if no file exists for the provided key.
  ///
  /// ### Example
  /// ```dart
  /// final fileData = request.getFileData('avatar');
  /// if (fileData != null) {
  ///   print('Filename: ${fileData['fileName']}');
  ///   print('Size: ${fileData['size']} bytes');
  /// }
  /// ```
  Map<String, dynamic>? getFileData(String key) => _body?.$2[key];

  /// Returns metadata for all uploaded files as a `Map<String, dynamic>`.
  ///
  /// The returned map contains one entry per file field, where each value is a
  /// map with the following structure:
  /// - `fileName`: The original name of the uploaded file.
  /// - `size`: The file size in bytes.
  /// - `content`: The file content as raw bytes (`List<int>`).
  /// - `tempFilePath`: Path to the temp file if saved via `getFile()` (optional).
  ///
  /// ### Example
  /// ```dart
  /// final files = request.getAllFileData();
  /// files?.forEach((key, fileData) {
  ///   print('Field: $key');
  ///   print('Filename: ${fileData['fileName']}');
  /// });
  /// ```
  Map<String, dynamic>? getAllFileData() => _body?.$2;

  void _trackTempFile(String path) {
    if (tempFilePathList == null) {
      tempFilePathList = [];
      tempFilePathList!.add(path);
    } else {
      tempFilePathList!.add(path);
    }
  }

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

  dynamic _contextData;

  /// Stores custom data to be passed from middleware to later middleware
  /// or request handlers during the lifecycle of a single request.
  ///
  /// This is especially useful for:
  /// - Passing authenticated user info
  /// - Sharing decoded JWT tokens
  /// - Storing preprocessed request metadata
  ///
  /// ### Example:
  /// ```dart
  /// request.setContextData = {'userId': 42, 'role': 'admin'};
  /// ```
  set setContextData(dynamic data) {
    _contextData = data;
  }

  /// Retrieves context data previously set using [setContextData].
  ///
  /// This allows access to middleware-provided information in your handler logic
  /// or in later middleware wrappers.
  ///
  /// ### Example:
  /// ```dart
  /// final data = request.getContextData;
  /// final userId = data?['userId'];
  /// ```
  dynamic get getContextData => _contextData;

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

  /// Returns the path of the request URL (e.g., `/api/user`).
  ///
  /// This excludes query parameters and scheme/host details.
  ///
  /// ### Example
  /// ```dart
  /// final routePath = request.path;
  /// if (routePath == '/login') {
  ///   // Handle login route
  /// }
  /// ```
  String get path => _request.uri.path;

  /// Returns the original [HttpRequest] object from `dart:io`.
  ///
  /// Useful if you need to access low-level request data directly.
  ///
  /// ### Example
  /// ```dart
  /// final connectionInfo = request.rawHttpRequest.connectionInfo;
  /// ```
  HttpRequest get rawHttpRequest => _request;

  /// Merges and returns all fields from path variables, query parameters,
  /// and JSON body into a single map.
  ///
  /// Priority (in case of key conflicts): JSON body > query params > path variables.
  Map<String, dynamic> get getAllFields => {
        ..._pathVariables, // lowest priority
        ...allQueryParams,
        ...(_body?.$1 ?? {}), // highest priority
      };
}
