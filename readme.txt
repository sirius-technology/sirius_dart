give me proper readme file for my dart package or my Sirius Framework

this are my files or code

This is Sirius class

import 'dart:io';

import 'package:sirius_backend/sirius_backend.dart';
import 'package:sirius_backend/src/constants.dart';
import 'package:sirius_backend/src/handler.dart';
import 'package:sirius_backend/src/helpers/logging.dart';

/// Sirius is a lightweight HTTP and WebSocket server framework for Dart.
///
/// It provides easy-to-use routing, middleware support, and WebSocket handling.
///
/// ### Basic Example:
///
/// ```dart
/// final Sirius sirius = Sirius();
///
/// sirius.get('/hello', (req) async => Response.send('Hello World'));
///
/// await sirius.start(port: 3000);
/// ```
///
/// ### Grouped Routes:
/// ```dart
/// sirius.group('/api', (group) {
///   group.get('/users', userController.getUsersHandler);
///   group.post('/users', userController.createUserHandler);
/// });
/// ```
class Sirius {
  final Map<String,
          Map<String, List<Future<Response> Function(Request request)>>>
      _routesMap = {};
  final Map<String, void Function(WebSocket socket)> _socketRoutesMap = {};
  final List<Future<Response> Function(Request request)> _beforeMiddlewareList =
      [];
  final List<Future<Response> Function(Request request)> _afterMiddlewareList =
      [];
  final Handler _handler = Handler();
  HttpServer? _server;

  String _autoAddSlash(String path) {
    if (path.startsWith("/")) {
      return path;
    }
    return "/$path";
  }

  /// Registers a middleware to run before each request.
  void useBefore(Middleware middleware) {
    _beforeMiddlewareList.add(middleware.handle);
  }

  /// Registers a middleware to run after each request.
  void useAfter(Middleware middleware) {
    _afterMiddlewareList.add(middleware.handle);
  }

  /// Groups routes under a common prefix.
  ///
  /// ```dart
  /// sirius.group('/api', (group) {
  ///   group.get('/users', userController.getUsersHandler);
  /// });
  /// ```
  void group(String prefix, void Function(Sirius sirius) callback) {
    prefix = _autoAddSlash(prefix);

    Sirius siriusGroup = Sirius();

    siriusGroup._beforeMiddlewareList.addAll(_beforeMiddlewareList);
    siriusGroup._afterMiddlewareList.addAll(_afterMiddlewareList);

    callback(siriusGroup);

    siriusGroup._routesMap.forEach((key, value) {
      _routesMap["$prefix$key"] = value;
    });
    siriusGroup._socketRoutesMap.forEach((key, value) {
      _socketRoutesMap["$prefix$key"] = value;
    });
  }

  /// Registers a GET route.
  void get(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, GET, handler, useBefore, useAfter);
  }

  /// Registers a POST route.
  void post(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, POST, handler, useBefore, useAfter);
  }

  /// Registers a PUT route.
  void put(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, PUT, handler, useBefore, useAfter);
  }

  /// Registers a DELETE route.
  void delete(
    String path,
    Future<Response> Function(Request request) handler, {
    List<Middleware> useBefore = const [],
    List<Middleware> useAfter = const [],
  }) {
    path = _autoAddSlash(path);
    _addRoute(path, DELETE, handler, useBefore, useAfter);
  }

  void _addRoute(
    String path,
    String method,
    Future<Response> Function(Request request) handler,
    List<Middleware> beforeMiddlewares,
    List<Middleware> afterMiddlewares,
  ) {
    List<Future<Response> Function(Request request)> beforeRouteMiddlewareList =
        beforeMiddlewares.map((mw) => mw.handle).toList();

    List<Future<Response> Function(Request request)> afterRouteMiddlewareList =
        afterMiddlewares.map((mw) => mw.handle).toList();

    List<Future<Response> Function(Request request)> middlewareHandlerList = [
      ..._beforeMiddlewareList,
      ...beforeRouteMiddlewareList,
      handler,
      ...afterRouteMiddlewareList,
      ..._afterMiddlewareList,
    ];

    if (_routesMap.containsKey(path)) {
      if (_routesMap[path]!.containsKey(method)) {
        throwError("path {$path} and method {$method} is already registered.");
      } else {
        _routesMap[path]![method] = middlewareHandlerList;
      }
      return;
    }
    _routesMap[path] = {method: middlewareHandlerList};
  }

  /// Registers a WebSocket route.
  ///
  /// ```dart
  /// sirius.webSocket('/chat', (socket) {
  ///   socket.listen((message) => socket.add('Echo: \$message'));
  /// });
  /// ```
  void webSocket(String path, void Function(WebSocket socket) handler) {
    path = _autoAddSlash(path);

    if (_socketRoutesMap.containsKey(path)) {
      throwError("WebSocket path {$path} is already registered.");
    } else {
      _socketRoutesMap[path] = handler;
    }
  }

  /// Starts the server on the given [port].
  ///
  /// ```dart
  /// int port = 3000;
  /// await sirius.start(port: port); // default port is 3333
  /// ```
  Future<void> start({
    int port = 3333,
    Function(HttpServer server)? callback,
  }) async {
    _handler.registerRoutes(_routesMap, _socketRoutesMap);
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

    if (callback != null) {
      callback(_server!);
    }

    await for (HttpRequest request in _server!) {
      _handler.handleRequest(request);
    }
  }

  /// Closes the HTTP server gracefully.
  Future<void> close({bool force = false}) async {
    if (_server != null) {
      await _server!.close(force: force);
    }
  }
}

This is my Request class

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

This is my Response class

import 'dart:io';

/// Represents an HTTP response structure used in the Sirius backend framework.
///
/// The `Response` class encapsulates the response data, HTTP status code,
/// and a flag to indicate if the request should proceed to the next handler.
///
/// ### Example
/// ```dart
/// final response = Response.send({"message": "Success"}, status: HttpStatus.ok);
/// return response;
/// ```
class Response {
  /// The actual data to return in the HTTP response.
  dynamic data;

  /// The HTTP status code of the response. Defaults to 200 (OK).
  int statusCode;

  /// A flag that indicates whether the current middleware/controller should pass control to the next.
  ///
  /// If `isNext` is `true`, it means the middleware should call the next handler in the pipeline.
  bool isNext = false;

  dynamic passedData;

  /// Creates a new `Response` object with the given [data] and [statusCode].
  ///
  /// Set [isNext] to true if you want this response to indicate that the next handler should be executed.
  ///
  /// ### Example
  /// ```dart
  /// final customResponse = Response({"result": "done"}, HttpStatus.created);
  /// ```
  Response(
      [this.data,
      this.statusCode = HttpStatus.ok,
      this.isNext = false,
      this.passedData]);

  /// Factory method to create a standard response with optional status code.
  ///
  /// [data] is the response body, and [status] is the HTTP status code (default is 200 OK).
  ///
  /// ### Example
  /// ```dart
  /// return Response.send({"message": "Data saved successfully"}, status: HttpStatus.ok);
  /// ```
  static Response send(dynamic data, {int status = HttpStatus.ok}) {
    return Response(data, status);
  }

  /// Returns a [Response] object that signals the framework to continue
  /// to the next middleware or final handler.
  ///
  /// This is typically used inside middleware when you want to allow
  /// the request to proceed without stopping the processing chain.
  ///
  /// You can optionally pass data using [passData], which will be accessible
  /// to subsequent middleware or handlers via the request context.
  ///
  /// ### Example
  /// ```dart
  /// if (!authenticated) {
  ///   return Response.send({"error": "Unauthorized"}, status: HttpStatus.unauthorized);
  /// }
  ///
  /// // Continue to the next middleware or handler
  /// return Response.next(passData: {"userId": 123});
  /// ```
  static Response next({dynamic passData}) {
    return Response(null, HttpStatus.ok, true, passData);
  }
}

This is my Validator class

import 'package:sirius_backend/sirius_backend.dart';

/// A utility class to validate incoming request data against
/// a set of defined [ValidationRules] for each field.
///
/// Example usage:
/// ```dart
/// Map<String, ValidationRules> rules = {
///   "email": ValidationRules(required : required()),
///   "age": ValidationRules(minNumber : minNumber(18)),
/// };
///
/// final validator = Validator(request, rules);
///
/// if (!validator.validate()) {
///   return Response.badRequest(body: validator.getAllErrors);
/// }
/// ```
class Validator {
  /// Constructs a [Validator] instance with a [Request] and validation [rules].
  ///
  /// The request body is parsed as JSON and stored internally.
  ///
  /// Throws an [Exception] if the request body is missing or not JSON.
  Validator(this.fields, this.rules);

  Map<String, dynamic> fields;
  final Map<String, ValidationRules> rules;
  final Map<String, String> _errorsMap = {};

  /// Validates the request data against the provided rules.
  ///
  /// Returns `true` if all fields pass validation, otherwise `false`.
  ///
  /// Use [getAllErrors] or [getError] to retrieve the validation error(s).
  ///
  /// Throws an [Exception] if a rule expects a specific data type but receives an incompatible value.
  bool validate() {
    _errorsMap.clear();

    for (MapEntry<String, ValidationRules> val in rules.entries) {
      var value = fields[val.key];
      String field = val.key;
      ValidationRules rule = val.value;

      if (rule.nullable && value == null) {
        continue;
      }

      // Required Validation
      if (rule.required != null) {
        if (value == null) {
          _errorsMap[field] = rule.required!.$2 ?? "$field is required";
          continue;
        }
        if (rule.required!.$1 && value is String && value.trim().isEmpty) {
          _errorsMap[field] =
              rule.required!.$2 ?? "$field is required and should not be empty";
          continue;
        }
      }

      // Data Type Validation
      if (rule.dataType != null) {
        switch (rule.dataType!.$1) {
          case DataTypes.STRING:
            if (value is! String) {
              _errorsMap[field] =
                  rule.dataType!.$2 ?? "$field must be a string";
              continue;
            }
            break;

          case DataTypes.NUMBER:
            if (value is! num) {
              _errorsMap[field] =
                  rule.dataType!.$2 ?? "$field must be a number";
              continue;
            }
            break;

          case DataTypes.BOOLEAN:
            if (value is! bool) {
              _errorsMap[field] =
                  rule.dataType!.$2 ?? "$field must be a boolean";
              continue;
            }
            break;

          case DataTypes.MAP:
            if (value is! Map<String, dynamic>) {
              _errorsMap[field] =
                  rule.dataType!.$2 ?? "$field must be an object";
              continue;
            }
            break;

          case DataTypes.LIST:
            if (value is! List<dynamic>) {
              _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a list";
              continue;
            }
            break;
        }
      }

      // Min Length Validation
      if (rule.minLength != null) {
        if (value.toString().length < rule.minLength!.$1) {
          _errorsMap[field] = rule.minLength!.$2 ??
              "$field must be at least ${rule.minLength!.$1} characters";
          continue;
        }
      }

      // Max Length Validation
      if (rule.maxLength != null) {
        if (value.toString().length > rule.maxLength!.$1) {
          _errorsMap[field] = rule.maxLength!.$2 ??
              "$field must not exceed ${rule.maxLength!.$1} characters";
          continue;
        }
      }

      // Exact Length Validation
      if (rule.exactLength != null) {
        if (value.toString().length != rule.exactLength!.$1) {
          _errorsMap[field] = rule.exactLength!.$2 ??
              "$field must be exactly ${rule.exactLength!.$1} characters";
          continue;
        }
      }

      // Min Number Validation
      if (rule.minNumber != null) {
        if (value is! num) {
          throw Exception(
              "Invalid data type: '$field' must be a number for minimum number validation.");
        }

        if (value < rule.minNumber!.$1) {
          _errorsMap[field] = rule.minNumber!.$2 ??
              "$field must be at least ${rule.minNumber!.$1}";
          continue;
        }
      }

      // Max Number Validation
      if (rule.maxNumber != null) {
        if (value is! num) {
          throw Exception(
              "Invalid data type: '$field' must be a number for maximum number validation.");
        }

        if (value > rule.maxNumber!.$1) {
          _errorsMap[field] = rule.maxNumber!.$2 ??
              "$field must not exceed ${rule.maxNumber!.$1}";
          continue;
        }
      }

      // Exact Number Validation
      if (rule.exactNumber != null) {
        if (value is! num) {
          throw Exception(
              "Invalid data type: '$field' must be a number for exact number validation.");
        }

        if (value != rule.exactNumber!.$1) {
          _errorsMap[field] = rule.exactNumber!.$2 ??
              "$field must be exactly ${rule.exactNumber!.$1}";
          continue;
        }
      }

      // Email Validation
      if (rule.validEmail != null) {
        if (value is! String) {
          throw Exception(
              "Invalid data type: '$field' must be a string for email validation.");
        }

        RegExp emailRegex =
            RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
        if (!emailRegex.hasMatch(value)) {
          _errorsMap[field] = rule.validEmail!.$1 ?? "Invalid email format";
          continue;
        }
      }

      // URL Validation
      if (rule.validUrl != null) {
        if (value is! String) {
          throw Exception(
              "Invalid data type: '$field' must be a string for url validation.");
        }

        RegExp urlRegex = RegExp(
            r"^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$");
        if (!urlRegex.hasMatch(value)) {
          _errorsMap[field] = rule.validUrl!.$1 ?? "Invalid URL format";
          continue;
        }
      }

      // Valid DateTime Validation
      if (rule.validDate != null) {
        if (value is! String) {
          throw Exception(
              "Invalid data type: '$field' must be a string for datetime validation.");
        }

        if (rule.validDate!.$1 == null) {
          RegExp dateTimeRegex = RegExp(
              r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
          if (!dateTimeRegex.hasMatch(value)) {
            _errorsMap[field] = rule.validDate!.$2 ?? "Invalid datetime format";
            continue;
          }
        } else {
          switch (rule.validDate!.$1!) {
            case DateTimeFormat.DATE:
              RegExp dateRegex =
                  RegExp(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$");
              if (!dateRegex.hasMatch(value)) {
                _errorsMap[field] = rule.validDate!.$2 ?? "Invalid date format";
                continue;
              }
              break;

            case DateTimeFormat.TIME:
              RegExp timeRegex =
                  RegExp(r"^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
              if (!timeRegex.hasMatch(value)) {
                _errorsMap[field] = rule.validDate!.$2 ?? "Invalid time format";
                continue;
              }
              break;

            case DateTimeFormat.DATETIME:
              RegExp dateTimeRegex = RegExp(
                  r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
              if (!dateTimeRegex.hasMatch(value)) {
                _errorsMap[field] =
                    rule.validDate!.$2 ?? "Invalid datetime format";
                continue;
              }
              break;
          }
        }
      }

      // In List Validation
      if (rule.inList != null) {
        if (!rule.inList!.$1.contains(value)) {
          _errorsMap[field] = rule.inList!.$2 ??
              "$field should be one of: ${rule.inList!.$1.join(', ')}";
          continue;
        }
      }

      // Not In List Validation
      if (rule.notInList != null) {
        if (rule.notInList!.$1.contains(value)) {
          _errorsMap[field] = rule.notInList!.$2 ??
              "$field must not be one of: ${rule.notInList!.$1.join(', ')}";
          continue;
        }
      }

      // Nested Map Validation
      if (rule.childMap != null && rule.childMap!.isNotEmpty) {
        if (value is! Map<String, dynamic>) {
          throw Exception(
              "Invalid data type: '$field' must be an object for nested map validation.");
        }

        Validator childValidator = Validator(value, rule.childMap!);
        if (!childValidator.validate()) {
          childValidator.getAllErrors.forEach((key, val) {
            _errorsMap["$field.$key"] = val;
          });
          continue;
        }
      }

      // Nested List Validation
      if (rule.childList != null && rule.childList!.isNotEmpty) {
        if (value is! List<dynamic>) {
          throw Exception(
              "Invalid data type: '$field' must be a List for nested list validation.");
        }

        Map<String, dynamic> listFieldMap = {
          for (int i = 0; i < value.length; i++) i.toString(): value[i]
        };

        Map<String, ValidationRules> listRuleMap = {
          for (int i = 0; i < rule.childList!.length; i++)
            i.toString(): rule.childList![i]
        };

        Validator childValidator = Validator(listFieldMap, listRuleMap);

        if (!childValidator.validate()) {
          childValidator.getAllErrors.forEach((key, val) {
            _errorsMap["$field.$key"] = val;
          });
          continue;
        }
      }

      // Custom Regex Validation
      if (rule.regex != null) {
        if (value is! String) {
          throw Exception(
              "Invalid data type: '$field' must be a string for regex validation.");
        }
        RegExp customRegex = RegExp(rule.regex!.$1);
        if (!customRegex.hasMatch(value)) {
          _errorsMap[field] = rule.regex!.$2 ?? "Invalid format";
          continue;
        }
      }

      // Custom Callback Function Validation
      if (rule.callback != null) {
        bool isValid = rule.callback!.$1(value);

        if (!isValid) {
          _errorsMap[field] = rule.callback!.$2;
          continue;
        }
      }
    }

    return _errorsMap.isEmpty;
  }

  /// Returns a map of all validation errors.
  ///
  /// Each key represents the field name, and the value is the error message.
  ///
  /// Example output:
  /// ```dart
  /// {
  ///   "email": "Email is required",
  ///   "age": "Age must be at least 18"
  /// }
  /// ```
  Map<String, String> get getAllErrors => _errorsMap;

  /// Returns the first validation error as a [MapEntry].
  ///
  /// Useful when only the first error matters, such as for immediate UI feedback.
  ///
  /// Example:
  /// ```dart
  /// final error = validator.getError;
  /// print("${error.key} => ${error.value}");
  /// ```
  MapEntry<String, String> get getError => _errorsMap.entries.first;
}

This is my ValidationRules class

import 'enums/data_types.dart';
import 'enums/date_time_formats.dart';

/// A class that holds various validation rules for input fields.
///
/// Example:
/// ```dart
/// final rules = ValidationRules(
///   required: required("This field is required"),
///   minLength: minLength(3, "Minimum 3 characters"),
///   validEmail: validEmail("Invalid email format"),
/// );
/// ```
class ValidationRules {
  /// Field must not be null.
  (bool, String?)? required;

  /// Whether the field is allowed to be null.
  /// If true, null values are accepted even if other rules are defined.
  bool nullable;

  /// Field must match a specific [DataTypes] type.
  (DataTypes, String?)? dataType;

  /// Minimum length of a string.
  (int, String?)? minLength;

  /// Maximum length of a string.
  (int, String?)? maxLength;

  /// Exact length of a string.
  (int, String?)? exactLength;

  /// Minimum value for a number.
  (int, String?)? minNumber;

  /// Maximum value for a number.
  (int, String?)? maxNumber;

  /// Exact value for a number.
  (int, String?)? exactNumber;

  /// Field must be a valid email.
  (String?,)? validEmail;

  /// Field must be a valid URL.
  (String?,)? validUrl;

  /// Field must be a valid date.
  (DateTimeFormat?, String?)? validDate;

  /// Field must be one of the provided options.
  (List<dynamic>, String?)? inList;

  /// Field must be one of the provided options.
  (List<dynamic>, String?)? notInList;

  /// Defines nested validation rules for child fields when the current field is a map.
  ///
  /// Use this to apply validation to each key inside a nested object.
  /// Each key in the `Map<String, ValidationRules>` represents a nested field
  /// and its corresponding validation rules.
  ///
  /// Example:
  /// ```dart
  /// child: {
  ///   'street': ValidationRules(required: required()),
  ///   'zip': ValidationRules(minLength: minLength(5))
  /// }
  /// ```
  Map<String, ValidationRules>? childMap;

  /// Defines nested validation rules for each item in a list when the current field is a list.
  ///
  /// Use this to apply validation to each element inside a list. Each item in the list
  /// is expected to follow the provided `ValidationRules`.
  ///
  /// Example:
  /// ```dart
  /// childList: [
  ///   ValidationRules(required: required()),
  ///   ValidationRules(minLength: minLength(3))
  /// ]
  /// ```
  ///
  /// Note: If the list contains objects/maps, use `childMap` within each `ValidationRules`
  /// to define validations for nested fields.
  List<dynamic>? childList;

  /// Field must match the given regular expression.
  (String, String?)? regex;

  /// Custom validation using a callback.
  (bool Function(dynamic value), String)? callback;

  ValidationRules({
    this.required,
    this.nullable = false,
    this.dataType,
    this.minLength,
    this.maxLength,
    this.exactLength,
    this.minNumber,
    this.maxNumber,
    this.exactNumber,
    this.validEmail,
    this.validUrl,
    this.validDate,
    this.inList,
    this.notInList,
    this.childMap,
    this.childList,
    this.regex,
    this.callback,
  });
}

/// Requires the field to be non-null.
///
/// Example:
/// ```dart
/// required("This field is required")
/// ```
(bool, String?) required({bool filled = true, String? message}) =>
    (filled, message);

/// Validates the data type.
///
/// Example:
/// ```dart
/// dataType(DataTypes.STRING, "Must be a string")
/// ```
(DataTypes, String?) dataType(DataTypes type, {String? message}) =>
    (type, message);

/// Validates minimum string length.
///
/// Example:
/// ```dart
/// minLength(3, "At least 3 characters required")
/// ```
(int, String?) minLength(int lenght, {String? message}) => (lenght, message);

/// Validates maximum string length.
///
/// Example:
/// ```dart
/// maxLength(10, "At most 10 characters allowed")
/// ```
(int, String?) maxLength(int lenght, {String? message}) => (lenght, message);

/// Validates exact string length.
///
/// Example:
/// ```dart
/// exactLength(5, "Must be 5 characters")
/// ```
(int, String?) exactLength(int lenght, {String? message}) => (lenght, message);

/// Validates minimum numeric value.
///
/// Example:
/// ```dart
/// minNumber(1, "Value must be at least 1")
/// ```
(int, String?) minNumber(int number, {String? message}) => (number, message);

/// Validates maximum numeric value.
///
/// Example:
/// ```dart
/// maxNumber(100, "Cannot exceed 100")
/// ```
(int, String?) maxNumber(int number, {String? message}) => (number, message);

/// Validates exact numeric value.
///
/// Example:
/// ```dart
/// exactNumber(42, "Value must be 42")
/// ```
(int, String?) exactNumber(int number, {String? message}) => (number, message);

/// Validates email format.
///
/// Example:
/// ```dart
/// validEmail("Invalid email format")
/// ```
(String?,) validEmail({String? message}) => (message,);

/// Validates URL format.
///
/// Example:
/// ```dart
/// validUrl("Invalid URL")
/// ```
(String?,) validUrl({String? message}) => (message,);

/// Validates date format.
///
/// Example:
/// ```dart
/// validDate(DateTimeFormat.DATETIME, "Invalid date")
/// ```
(DateTimeFormat, String?) validDate(
        {DateTimeFormat format = DateTimeFormat.DATETIME, String? message}) =>
    (format, message);

/// Validates that the value exists within the provided list of allowed values.
///
/// Example:
/// ```dart
/// inList(['admin', 'user', 'guest'], "Role must be one of: admin, user, guest")
/// ```
///
/// - [values]: A list of allowed values.
/// - [message]: Optional custom error message to display when validation fails.
(List<dynamic>, String?) inList(List<dynamic> values, {String? message}) =>
    (values, message);

/// Validates that the value does **not** exist within the provided list of disallowed values.
///
/// Example:
/// ```dart
/// notInList(['banned', 'restricted'], "This value is not allowed")
/// ```
///
/// - [values]: A list of disallowed values.
/// - [message]: Optional custom error message to display when validation fails.
(List<dynamic>, String?) notInList(List<dynamic> values, {String? message}) =>
    (values, message);

/// Validates a custom regular expression.
///
/// Example:
/// ```dart
/// regex(r'^\\d{4}\$', "Must be a 4-digit number")
/// ```
(String, String?) regex(String pattern, {String? message}) =>
    (pattern, message);

/// Custom validation callback.
///
/// Example:
/// ```dart
/// callback((value) => value == "admin", "Only 'admin' is allowed")
/// ```
(bool Function(dynamic value), String) callback(
        bool Function(dynamic value) validate,
        {required String message}) =>
    (validate, message);


please give me proper readme file and documentations

where developers can see my readme file and understand code how to use