import 'dart:io';

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
  Validator(this.request, this.rules);

  /// A global flag that enables or disables type safety checks during validation.
  ///
  /// When `true`, the [Validator] will **not throw exceptions** for data type mismatches,
  /// but instead log them as validation errors in [getAllErrors].
  ///
  /// When `false`, the [Validator] will throw an [Exception] immediately upon encountering
  /// a rule that expects a specific data type but receives an incompatible value.
  ///
  /// By default `Validation.enableTypeSafety = true;`
  ///
  /// This is useful for controlling whether your framework should crash fast (for debugging),
  /// or fail gracefully (for production environments).
  ///
  /// You can override this per-validation call using the `typeSafety` parameter in [validate()].
  ///
  /// ### Example:
  /// ```dart
  /// // Disable type safety globally
  /// Validator.enableTypeSafety = false;
  ///
  /// final validator = Validator(fields, rules);
  ///
  /// // Will throw an exception if a type mismatch is encountered
  /// validator.validate();
  ///
  /// // Or enable type safety for a single validation run:
  /// validator.validate(typeSafety: true);
  /// ```
  static bool enableTypeSafety = true;

  final Request request;
  final Map<String, ValidationRules> rules;
  final Map<String, String> _errorsMap = {};

  /// Validates the provided [fields] against the defined [rules].
  ///
  /// This method runs all validation checks configured via [ValidationRules]
  /// such as required fields, data types, length, numeric range, email, URL,
  /// date formats, nested structures, and custom validations.
  ///
  /// Returns `true` if all fields pass validation, otherwise returns `false`.
  ///
  /// If validation fails, the specific error messages can be retrieved using:
  /// - [getAllErrors] for all errors as a `Map<String, String>`
  /// - [getError] for the first error as a `MapEntry<String, String>`
  ///
  /// ### Type Safety
  /// - By default, the method uses the static global flag [enableTypeSafety].
  /// - You can override it per-validation call using the [typeSafety] parameter.
  /// - When enabled (`true`), incompatible types are logged as validation errors.
  /// - When disabled (`false`), type mismatches throw exceptions immediately.
  ///
  /// ### Automatic Parsing
  /// - Controlled by the `parsing` parameter (default `true`) or global [enableParsing].
  /// - When enabled, string values are automatically coerced to numbers or booleans
  ///   if the corresponding [ValidationRules] expect a numeric or boolean type.
  /// - This is especially useful for query parameters or path variables
  ///   that are always received as strings in HTTP requests.
  /// - When disabled, values are validated as-is without any type coercion.
  ///
  /// ### Example:
  /// ```dart
  /// final validator = Validator({
  ///   "email": "user@example.com",
  ///   "age": 17,
  /// }, {
  ///   "email": ValidationRules(validEmail: validEmail()),
  ///   "age": ValidationRules(minNumber: minNumber(18)),
  /// });
  ///
  /// if (!validator.validate()) {
  ///   print(validator.getAllErrors);
  /// }
  /// ```
  /// ### Override type safety or parsing for a single run:
  /// ```dart
  /// validator.validate(typeSafety: false, parsing: false);
  /// ```
  /// ### Override type safety for a single run:
  /// ```dart
  /// validator.validate(typeSafety: false); // Will throw on type errors
  /// ```
  /// ### Override type parsing for a single run:
  /// ```dart
  /// validator.validate(parsing: false); // Will validate on type errors
  /// ```

  (Map<String, String>, Map<String, dynamic>) _segregateFields() {
    HttpRequest rawRequest = request.rawHttpRequest;

    Map<String, String> fieldStrings = {
      ...request.allPathVariables,
      ...request.allQueryParams,
    };

    Map<String, dynamic> fieldDynamics = {};

    final contentType = rawRequest.headers.contentType;
    final mimeType = contentType?.mimeType;

    if (mimeType == null) {
      return (fieldStrings, fieldDynamics);
    } else if (mimeType == 'application/json') {
      fieldDynamics = {...fieldDynamics, ...request.getBody};
      return (fieldStrings, fieldDynamics);
    } else if (mimeType == 'application/x-www-form-urlencoded') {
      fieldStrings = {...fieldStrings, ...request.getBody};
      return (fieldStrings, fieldDynamics);
    } else if (mimeType == 'text/plain') {
      fieldStrings = {...fieldStrings, ...request.getBody};
      return (fieldStrings, fieldDynamics);
    }
    // need to add formdata also
    else {
      return (fieldStrings, fieldDynamics);
    }
  }

  bool validate({bool? typeSafety}) {
    bool isTypeSafety = enableTypeSafety;
    if (typeSafety != null) {
      isTypeSafety = typeSafety;
    }

    _errorsMap.clear();

    final (fieldStrings, fieldDynamics) = _segregateFields();

    bool isValidate = false;
    isValidate = _internalValidate(fieldStrings, rules, isTypeSafety, true);
    isValidate = _internalValidate(fieldDynamics, rules, isTypeSafety, false);

    return isValidate;
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

  bool _internalValidate(Map<String, dynamic> fields,
      Map<String, ValidationRules> r, bool isTypeSafety, bool isString) {
    for (MapEntry<String, ValidationRules> e in r.entries) {
      if (isString) {
        _validateStrings(fields[e.key], e, isTypeSafety);
      } else {
        _validateDynamics(fields[e.key], e, isTypeSafety);
      }
    }

    return _errorsMap.isEmpty;
  }

  void _validateStrings(
      String? value, MapEntry<String, ValidationRules> r, bool isTypeSafety) {
    final String field = r.key;
    final ValidationRules rule = r.value;

    if (rule.nullable && value == null) {
      return;
    }

    // Required Validation
    if (rule.required != null) {
      if (value == null) {
        _errorsMap[field] = rule.required!.$2 ?? "$field is required";
        return;
      }
      if (rule.required!.$1 && value.trim().isEmpty) {
        _errorsMap[field] =
            rule.required!.$2 ?? "$field is required and should not be empty";
        return;
      }
    }

    value!;

    // Data Type Validation
    if (rule.dataType != null) {
      switch (rule.dataType!.$1) {
        case DataTypes.STRING:
          // Value is always string because passing only string values
          break;
        case DataTypes.NUMBER:
          if (num.tryParse(value) == null) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a number";
            return;
          }

          break;
        case DataTypes.BOOLEAN:
          if (bool.tryParse(value) == null) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a boolean";
            return;
          }
          break;
        case DataTypes.MAP:
          // Not checking in map because passing only string values
          break;
        case DataTypes.LIST:
          // Not checking in map because passing only string values
          break;
      }
    }

    // Min Length Validation
    if (rule.minLength != null) {
      if (value.length < rule.minLength!.$1) {
        _errorsMap[field] = rule.minLength!.$2 ??
            "$field must be at least ${rule.minLength!.$1} characters";
        return;
      }
    }

    // Max Length Validation
    if (rule.maxLength != null) {
      if (value.length > rule.maxLength!.$1) {
        _errorsMap[field] = rule.maxLength!.$2 ??
            "$field must not exceed ${rule.maxLength!.$1} characters";
        return;
      }
    }

    // Exact Length Validation
    if (rule.exactLength != null) {
      if (value.length != rule.exactLength!.$1) {
        _errorsMap[field] = rule.exactLength!.$2 ??
            "$field must be exactly ${rule.exactLength!.$1} characters";
        return;
      }
    }

    // Min Number Validation
    if (rule.minNumber != null) {
      num? n = num.tryParse(value);
      if (n == null) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a number for minimum number validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for minimum number validation");
      }
      if (n < rule.minNumber!.$1) {
        _errorsMap[field] = rule.minNumber!.$2 ??
            "$field must be at least ${rule.minNumber!.$1}";
        return;
      }
    }

    // Max Number Validation
    if (rule.maxNumber != null) {
      num? n = num.tryParse(value);
      if (n == null) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a number for maximum number validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for maximum number validation");
      }
      if (n > rule.maxNumber!.$1) {
        _errorsMap[field] = rule.maxNumber!.$2 ??
            "$field must not exceed ${rule.maxNumber!.$1}";
        return;
      }
    }

    // Exact Number Validation
    if (rule.exactNumber != null) {
      num? n = num.tryParse(value);
      if (n == null) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a number for exact number validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for exact number validation");
      }

      if (n != rule.exactNumber!.$1) {
        _errorsMap[field] = rule.exactNumber!.$2 ??
            "$field must be exactly ${rule.exactNumber!.$1}";
        return;
      }
    }

    // Email Validation
    if (rule.validEmail != null) {
      RegExp emailRegex =
          RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      if (!emailRegex.hasMatch(value)) {
        _errorsMap[field] = rule.validEmail!.$1 ?? "Invalid email format";
        return;
      }
    }

    // URL Validation
    if (rule.validUrl != null) {
      RegExp urlRegex = RegExp(
          r"^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$");
      if (!urlRegex.hasMatch(value)) {
        _errorsMap[field] = rule.validUrl!.$1 ?? "Invalid URL format";
        return;
      }
    }

    // Valid DateTime Validation
    if (rule.validDate != null) {
      if (rule.validDate!.$1 == null) {
        RegExp dateTimeRegex = RegExp(
            r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
        if (!dateTimeRegex.hasMatch(value)) {
          _errorsMap[field] = rule.validDate!.$2 ?? "Invalid datetime format";
          return;
        }
      } else {
        switch (rule.validDate!.$1!) {
          case DateTimeFormat.DATE:
            RegExp dateRegex =
                RegExp(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$");
            if (!dateRegex.hasMatch(value)) {
              _errorsMap[field] = rule.validDate!.$2 ?? "Invalid date format";
              return;
            }
            break;
          case DateTimeFormat.TIME:
            RegExp timeRegex =
                RegExp(r"^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!timeRegex.hasMatch(value)) {
              _errorsMap[field] = rule.validDate!.$2 ?? "Invalid time format";
              return;
            }
            break;

          case DateTimeFormat.DATETIME:
            RegExp dateTimeRegex = RegExp(
                r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!dateTimeRegex.hasMatch(value)) {
              _errorsMap[field] =
                  rule.validDate!.$2 ?? "Invalid datetime format";
              return;
            }
            break;
        }
      }
    }

    // // In List Validation
    // if (rule.inList != null) {
    //   if (!rule.inList!.$1.contains(value)) {
    //     _errorsMap[field] = rule.inList!.$2 ??
    //         "$field should be one of: ${rule.inList!.$1.join(', ')}";
    //     continue;
    //   }
    // }

    // // Not In List Validation
    // if (rule.notInList != null) {
    //   if (rule.notInList!.$1.contains(value)) {
    //     _errorsMap[field] = rule.notInList!.$2 ??
    //         "$field must not be one of: ${rule.notInList!.$1.join(', ')}";
    //     continue;
    //   }
    // }

    // // Nested Map Validation
    // if (rule.childMap != null && rule.childMap!.isNotEmpty) {
    //   if (value is! Map<String, dynamic>) {
    //     if (isTypeSafety) {
    //       _errorsMap[field] =
    //           "Invalid data type: '$field' must be an object for nested map validation";
    //       continue;
    //     }
    //     throw Exception(
    //         "Invalid data type: '$field' must be an object for nested map validation");
    //   }

    //   Validator childValidator = Validator(value, rule.childMap!);
    //   if (!childValidator.validate()) {
    //     childValidator.getAllErrors.forEach((key, val) {
    //       _errorsMap["$field.$key"] = val;
    //     });
    //     continue;
    //   }
    // }

    // // Nested List Validation
    // if (rule.childList != null && rule.childList!.isNotEmpty) {
    //   if (value is! List<dynamic>) {
    //     if (isTypeSafety) {
    //       _errorsMap[field] =
    //           "Invalid data type: '$field' must be a List for nested list validation";
    //       continue;
    //     }
    //     throw Exception(
    //         "Invalid data type: '$field' must be a List for nested list validation");
    //   }

    //   Map<String, dynamic> listFieldMap = {
    //     for (int i = 0; i < value.length; i++) i.toString(): value[i]
    //   };

    //   if (rule.childList!.last.isRuleForEachElement == true) {
    //     rule.childList = List.filled(value.length, rule.childList!.last);
    //   }

    //   Map<String, ValidationRules> listRuleMap = {
    //     for (int i = 0; i < rule.childList!.length; i++)
    //       i.toString(): rule.childList![i]
    //   };

    //   Validator childValidator = Validator(listFieldMap, listRuleMap);

    //   if (!childValidator.validate()) {
    //     childValidator.getAllErrors.forEach((key, val) {
    //       _errorsMap["$field.$key"] = val;
    //     });
    //     continue;
    //   }
    // }

    // Custom Regex Validation
    if (rule.regex != null) {
      RegExp customRegex = RegExp(rule.regex!.$1);
      if (!customRegex.hasMatch(value)) {
        _errorsMap[field] = rule.regex!.$2 ?? "Invalid format";
        return;
      }
    }

    // Custom Callback Function Validation
    if (rule.callback != null) {
      bool isValid = rule.callback!.$1(value);

      if (!isValid) {
        _errorsMap[field] = rule.callback!.$2;
        return;
      }
    }
  }

  void _validateDynamics(
      dynamic value, MapEntry<String, ValidationRules> r, bool isTypeSafety) {
    final String field = r.key;
    final ValidationRules rule = r.value;

    if (rule.nullable && value == null) {
      return;
    }

    // Required Validation
    if (rule.required != null) {
      if (value == null) {
        _errorsMap[field] = rule.required!.$2 ?? "$field is required";
        return;
      }
      if (rule.required!.$1 && value is String && value.trim().isEmpty) {
        _errorsMap[field] =
            rule.required!.$2 ?? "$field is required and should not be empty";
        return;
      }
    }

    // Data Type Validation
    if (rule.dataType != null) {
      switch (rule.dataType!.$1) {
        case DataTypes.STRING:
          if (value is! String) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a string";
            return;
          }
          break;

        case DataTypes.NUMBER:
          if (value is! num) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a number";
            return;
          }
          break;

        case DataTypes.BOOLEAN:
          if (value is! bool) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a boolean";
            return;
          }
          break;

        case DataTypes.MAP:
          if (value is! Map<String, dynamic>) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be an object";
            return;
          }
          break;

        case DataTypes.LIST:
          if (value is! List<dynamic>) {
            _errorsMap[field] = rule.dataType!.$2 ?? "$field must be a list";
            return;
          }
          break;
      }
    }

    // Min Length Validation
    if (rule.minLength != null) {
      if (value.toString().length < rule.minLength!.$1) {
        _errorsMap[field] = rule.minLength!.$2 ??
            "$field must be at least ${rule.minLength!.$1} characters";
        return;
      }
    }

    // Max Length Validation
    if (rule.maxLength != null) {
      if (value.toString().length > rule.maxLength!.$1) {
        _errorsMap[field] = rule.maxLength!.$2 ??
            "$field must not exceed ${rule.maxLength!.$1} characters";
        return;
      }
    }

    // Exact Length Validation
    if (rule.exactLength != null) {
      if (value.toString().length != rule.exactLength!.$1) {
        _errorsMap[field] = rule.exactLength!.$2 ??
            "$field must be exactly ${rule.exactLength!.$1} characters";
        return;
      }
    }

    // Min Number Validation
    if (rule.minNumber != null) {
      if (value is! num) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a number for minimum number validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for minimum number validation");
      }

      if (value < rule.minNumber!.$1) {
        _errorsMap[field] = rule.minNumber!.$2 ??
            "$field must be at least ${rule.minNumber!.$1}";
        return;
      }
    }

    // Max Number Validation
    if (rule.maxNumber != null) {
      if (value is! num) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a number for maximum number validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for maximum number validation");
      }

      if (value > rule.maxNumber!.$1) {
        _errorsMap[field] = rule.maxNumber!.$2 ??
            "$field must not exceed ${rule.maxNumber!.$1}";
        return;
      }
    }

    // Exact Number Validation
    if (rule.exactNumber != null) {
      if (value is! num) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a number for exact number validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for exact number validation");
      }

      if (value != rule.exactNumber!.$1) {
        _errorsMap[field] = rule.exactNumber!.$2 ??
            "$field must be exactly ${rule.exactNumber!.$1}";
        return;
      }
    }

    // Email Validation
    if (rule.validEmail != null) {
      if (value is! String) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a string for email validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for email validation");
      }

      RegExp emailRegex =
          RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      if (!emailRegex.hasMatch(value)) {
        _errorsMap[field] = rule.validEmail!.$1 ?? "Invalid email format";
        return;
      }
    }

    // URL Validation
    if (rule.validUrl != null) {
      if (value is! String) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a string for url validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for url validation");
      }

      RegExp urlRegex = RegExp(
          r"^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$");
      if (!urlRegex.hasMatch(value)) {
        _errorsMap[field] = rule.validUrl!.$1 ?? "Invalid URL format";
        return;
      }
    }

    // Valid DateTime Validation
    if (rule.validDate != null) {
      if (value is! String) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a string for datetime validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for datetime validation");
      }

      if (rule.validDate!.$1 == null) {
        RegExp dateTimeRegex = RegExp(
            r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
        if (!dateTimeRegex.hasMatch(value)) {
          _errorsMap[field] = rule.validDate!.$2 ?? "Invalid datetime format";
          return;
        }
      } else {
        switch (rule.validDate!.$1!) {
          case DateTimeFormat.DATE:
            RegExp dateRegex =
                RegExp(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$");
            if (!dateRegex.hasMatch(value)) {
              _errorsMap[field] = rule.validDate!.$2 ?? "Invalid date format";
              return;
            }
            break;

          case DateTimeFormat.TIME:
            RegExp timeRegex =
                RegExp(r"^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!timeRegex.hasMatch(value)) {
              _errorsMap[field] = rule.validDate!.$2 ?? "Invalid time format";
              return;
            }
            break;

          case DateTimeFormat.DATETIME:
            RegExp dateTimeRegex = RegExp(
                r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!dateTimeRegex.hasMatch(value)) {
              _errorsMap[field] =
                  rule.validDate!.$2 ?? "Invalid datetime format";
              return;
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
        return;
      }
    }

    // Not In List Validation
    if (rule.notInList != null) {
      if (rule.notInList!.$1.contains(value)) {
        _errorsMap[field] = rule.notInList!.$2 ??
            "$field must not be one of: ${rule.notInList!.$1.join(', ')}";
        return;
      }
    }

    // Nested Map Validation
    if (rule.childMap != null && rule.childMap!.isNotEmpty) {
      if (value is! Map<String, dynamic>) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be an object for nested map validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be an object for nested map validation");
      }

      final isChildValidate =
          _internalValidate(value, rule.childMap!, isTypeSafety, false);
      if (!isChildValidate) {
        _errorsMap.forEach((key, val) {
          _errorsMap["$field.$key"] = val;
        });
        return;
      }
    }

    // Nested List Validation
    if (rule.childList != null && rule.childList!.isNotEmpty) {
      if (value is! List<dynamic>) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a List for nested list validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a List for nested list validation");
      }

      Map<String, dynamic> listFieldMap = {
        for (int i = 0; i < value.length; i++) i.toString(): value[i]
      };

      if (rule.childList!.last.isRuleForEachElement == true) {
        rule.childList = List.filled(value.length, rule.childList!.last);
      }

      Map<String, ValidationRules> listRuleMap = {
        for (int i = 0; i < rule.childList!.length; i++)
          i.toString(): rule.childList![i]
      };

      final isChildValidate =
          _internalValidate(listFieldMap, listRuleMap, isTypeSafety, false);

      if (!isChildValidate) {
        _errorsMap.forEach((key, val) {
          _errorsMap["$field.$key"] = val;
        });
        return;
      }
    }

    // Custom Regex Validation
    if (rule.regex != null) {
      if (value is! String) {
        if (isTypeSafety) {
          _errorsMap[field] =
              "Invalid data type: '$field' must be a string for regex validation";
          return;
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for regex validation");
      }
      RegExp customRegex = RegExp(rule.regex!.$1);
      if (!customRegex.hasMatch(value)) {
        _errorsMap[field] = rule.regex!.$2 ?? "Invalid format";
        return;
      }
    }

    // Custom Callback Function Validation
    if (rule.callback != null) {
      bool isValid = rule.callback!.$1(value);

      if (!isValid) {
        _errorsMap[field] = rule.callback!.$2;
        return;
      }
    }
  }
}
