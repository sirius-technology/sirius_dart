import 'dart:io';

import 'package:sirius_backend/sirius_backend.dart';

/// A comprehensive request validation utility for the Sirius backend framework.
///
/// The [Validator] validates request input fields (from path variables, query
/// parameters, or body) against a set of defined [ValidationRules].
///
/// It supports:
/// - Type validation (`string`, `number`, `boolean`, `map`, `list`)
/// - Required and nullable fields
/// - Length and numeric constraints
/// - Email, URL, and Date format validation
/// - Nested object (`childMap`) and list (`childList`) validation
/// - Custom regex and callback validation
///
/// ### Example
/// ```dart
/// final rules = {
///   "email": ValidationRules(required: required(), validEmail: validEmail()),
///   "age": ValidationRules(minNumber: minNumber(18)),
/// };
///
/// final validator = Validator(request, rules);
///
/// if (!validator.validate()) {
///   return errorResponse(validator.getAllErrors, 422);
/// }
/// ```
class Validator {
  /// Creates a [Validator] instance using a [Request] and its validation [rules].
  ///
  /// The validator automatically segregates request fields into:
  /// - `fieldStrings`: String-based data (query/path/form fields)
  /// - `fieldDynamics`: Dynamic data (JSON or multipart)
  ///
  /// Throws an [Exception] if request body parsing fails.
  Validator(this.request, this.rules);

  /// Global flag to enable or disable type-safety across all validation calls.
  ///
  /// - When `true`, invalid data types **do not throw exceptions** —
  ///   instead, validation errors are recorded.
  /// - When `false`, validation stops immediately on type mismatches.
  ///
  /// Useful for switching between strict (debug) and safe (production) validation.
  ///
  /// Example:
  /// ```dart
  /// Validator.enableTypeSafety = false;
  /// ```
  static bool enableTypeSafety = true;

  final Request request;
  final Map<String, ValidationRules> rules;
  Map<String, String> _errorsMap = {};

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

  /// Executes validation for all fields extracted from the provided [Request].
  ///
  /// This method validates every field found in the request — including
  /// **path variables**, **query parameters**, and **body data** — against
  /// the corresponding [ValidationRules] defined in the rules map.
  ///
  /// The validation system ensures that all incoming data matches the expected
  /// structure, types, and constraints such as:
  /// - Required fields
  /// - Data types (string, number, boolean, etc.)
  /// - Length limits and numeric ranges
  /// - Format checks (email, URL, date)
  /// - Nested map or list structures
  /// - Custom validation logic
  ///
  /// ---
  ///
  /// ### ✅ Return Value
  /// - Returns `true` → All validations passed successfully.
  /// - Returns `false` → One or more validation rules failed.
  ///
  /// ---
  ///
  /// ### ⚙️ Parameters
  /// - **[typeSafety]** *(optional)* — Overrides the global `enableTypeSafety` flag
  ///   for this specific validation run.
  ///   - When `true`: incompatible types (e.g., a string instead of a number)
  ///     are treated as validation errors.
  ///   - When `false`: type mismatches throw runtime exceptions.
  ///
  /// ---
  ///
  /// ### 🔍 Error Handling
  /// When validation fails:
  /// - `getAllErrors` → Returns all errors as a `Map<String, String>`.
  /// - `getError` → Returns the first error as a `MapEntry<String, String>`.
  ///
  /// ---
  ///
  /// ### 💡 Example: Basic Usage
  /// ```dart
  /// final rules = {
  ///   "email": ValidationRules(validEmail: validEmail()),
  ///   "age": ValidationRules(minNumber: minNumber(18)),
  /// }
  /// final validator = Validator(request, rules);
  ///
  /// if (!validator.validate()) {
  ///   print(validator.getAllErrors);
  /// }
  /// ```
  ///
  /// ---
  ///
  /// ### 💡 Example: Override Type Safety
  /// ```dart
  /// validator.validate(typeSafety: false); // Throws if data types mismatch
  /// ```
  ///
  /// ---
  ///
  /// ### 🧠 Notes
  /// - Automatically collects and merges data from:
  ///   - Path variables
  ///   - Query parameters
  ///   - Request body
  /// - Runs child (nested) validations recursively for maps and lists.
  /// - Safe to call multiple times on the same validator instance.
  ///
  /// ---
  ///
  /// ### 🔧 Example of Nested Validation
  /// ```dart
  /// final validator = Validator(request, {
  ///   "items": ValidationRules(
  ///   required: required(),
  ///   dataType: dataType(DataTypes.LIST),
  ///   childList: ValidationRules(
  ///           required: required(), dataType: dataType(DataTypes.STRING))
  ///       .forEachElement(),
  /// ),
  /// });
  ///
  /// if (!validator.validate()) {
  ///   print(validator.getAllErrors);
  /// }
  /// ```
  bool validate({bool? typeSafety}) {
    bool isTypeSafety = enableTypeSafety;
    if (typeSafety != null) {
      isTypeSafety = typeSafety;
    }

    _errorsMap.clear();

    final (fieldStrings, fieldDynamics) = _segregateFields();

    _errorsMap =
        _internalValidate(fieldStrings, fieldDynamics, rules, isTypeSafety);

    return _errorsMap.isEmpty;
  }

  Map<String, String> _internalValidate(
      Map<String, String> fieldString,
      Map<String, dynamic> fieldDynamic,
      Map<String, ValidationRules> r,
      bool isTypeSafety) {
    Map<String, String> errors = {};

    for (MapEntry<String, ValidationRules> e in r.entries) {
      if (fieldString.containsKey(e.key)) {
        final error = _validateStrings(fieldString[e.key], e, isTypeSafety);
        if (error != null) {
          errors[error.$1] = error.$2;
        }
      } else {
        final error = _validateDynamics(fieldDynamic[e.key], e, isTypeSafety);
        if (error != null) {
          errors[error.$1] = error.$2;
        }
      }
    }

    return errors;
  }

  (String, String)? _validateStrings(
      String? value, MapEntry<String, ValidationRules> r, bool isTypeSafety) {
    final String field = r.key;
    final ValidationRules rule = r.value;
    (String, String)? error;

    if (rule.nullable && value == null) {
      return error;
    }

    // Required Validation
    if (rule.required != null) {
      if (value == null) {
        return (field, rule.required!.$2 ?? "$field is required");
      }
      if (rule.required!.$1 && value.trim().isEmpty) {
        return (
          field,
          rule.required!.$2 ?? "$field is required and should not be empty"
        );
      }
    }

    // Data Type Validation
    if (rule.dataType != null) {
      switch (rule.dataType!.$1) {
        case DataTypes.STRING:
          // Value is always string because passing only string values
          break;
        case DataTypes.NUMBER:
          if (num.tryParse(value!) == null) {
            return (field, rule.dataType!.$2 ?? "$field must be a number");
          }

          break;
        case DataTypes.BOOLEAN:
          if (bool.tryParse(value!) == null) {
            return (field, rule.dataType!.$2 ?? "$field must be a boolean");
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
      if (value!.length < rule.minLength!.$1) {
        return (
          field,
          rule.minLength!.$2 ??
              "$field must be at least ${rule.minLength!.$1} characters"
        );
      }
    }

    // Max Length Validation
    if (rule.maxLength != null) {
      if (value!.length > rule.maxLength!.$1) {
        return (
          field,
          rule.maxLength!.$2 ??
              "$field must not exceed ${rule.maxLength!.$1} characters"
        );
      }
    }

    // Exact Length Validation
    if (rule.exactLength != null) {
      if (value!.length != rule.exactLength!.$1) {
        return (
          field,
          rule.exactLength!.$2 ??
              "$field must be exactly ${rule.exactLength!.$1} characters"
        );
      }
    }

    // Min Number Validation
    if (rule.minNumber != null) {
      num? n = num.tryParse(value!);
      if (n == null) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a number for minimum number validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for minimum number validation");
      }
      if (n < rule.minNumber!.$1) {
        return (
          field,
          rule.minNumber!.$2 ?? "$field must be at least ${rule.minNumber!.$1}"
        );
      }
    }

    // Max Number Validation
    if (rule.maxNumber != null) {
      num? n = num.tryParse(value!);
      if (n == null) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a number for maximum number validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for maximum number validation");
      }
      if (n > rule.maxNumber!.$1) {
        return (
          field,
          rule.maxNumber!.$2 ?? "$field must not exceed ${rule.maxNumber!.$1}"
        );
      }
    }

    // Exact Number Validation
    if (rule.exactNumber != null) {
      num? n = num.tryParse(value!);
      if (n == null) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a number for exact number validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for exact number validation");
      }

      if (n != rule.exactNumber!.$1) {
        return (
          field,
          rule.exactNumber!.$2 ??
              "$field must be exactly ${rule.exactNumber!.$1}"
        );
      }
    }

    // Email Validation
    if (rule.validEmail != null) {
      RegExp emailRegex =
          RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      if (!emailRegex.hasMatch(value!)) {
        return (field, rule.validEmail!.$1 ?? "Invalid email format");
      }
    }

    // URL Validation
    if (rule.validUrl != null) {
      RegExp urlRegex = RegExp(
          r"^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$");
      if (!urlRegex.hasMatch(value!)) {
        return (field, rule.validUrl!.$1 ?? "Invalid URL format");
      }
    }

    // Valid DateTime Validation
    if (rule.validDate != null) {
      if (rule.validDate!.$1 == null) {
        RegExp dateTimeRegex = RegExp(
            r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
        if (!dateTimeRegex.hasMatch(value!)) {
          return (field, rule.validDate!.$2 ?? "Invalid datetime format");
        }
      } else {
        switch (rule.validDate!.$1!) {
          case DateTimeFormat.DATE:
            RegExp dateRegex =
                RegExp(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$");
            if (!dateRegex.hasMatch(value!)) {
              return (field, rule.validDate!.$2 ?? "Invalid date format");
            }
            break;
          case DateTimeFormat.TIME:
            RegExp timeRegex =
                RegExp(r"^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!timeRegex.hasMatch(value!)) {
              return (field, rule.validDate!.$2 ?? "Invalid time format");
            }
            break;

          case DateTimeFormat.DATETIME:
            RegExp dateTimeRegex = RegExp(
                r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!dateTimeRegex.hasMatch(value!)) {
              return (field, rule.validDate!.$2 ?? "Invalid datetime format");
            }
            break;
        }
      }
    }

    // // In List Validation
    // if (rule.inList != null) {
    //   if (!rule.inList!.$1.contains(value!)) {
    //     _errorsMap[field] = rule.inList!.$2 ??
    //         "$field should be one of: ${rule.inList!.$1.join(', ')}";
    //     continue;
    //   }
    // }

    // // Not In List Validation
    // if (rule.notInList != null) {
    //   if (rule.notInList!.$1.contains(value!)) {
    //     _errorsMap[field] = rule.notInList!.$2 ??
    //         "$field must not be one of: ${rule.notInList!.$1.join(', ')}";
    //     continue;
    //   }
    // }

    // // Nested Map Validation
    // if (rule.childMap != null && rule.childMap!.isNotEmpty) {
    //   if (value! is! Map<String, dynamic>) {
    //     if (isTypeSafety) {
    //       _errorsMap[field] =
    //           "Invalid data type: '$field' must be an object for nested map validation";
    //       continue;
    //     }
    //     throw Exception(
    //         "Invalid data type: '$field' must be an object for nested map validation");
    //   }

    //   Validator childValidator = Validator(value!, rule.childMap!);
    //   if (!childValidator.validate()) {
    //     childValidator.getAllErrors.forEach((key, val) {
    //       _errorsMap["$field.$key"] = val;
    //     });
    //     continue;
    //   }
    // }

    // // Nested List Validation
    // if (rule.childList != null && rule.childList!.isNotEmpty) {
    //   if (value! is! List<dynamic>) {
    //     if (isTypeSafety) {
    //       _errorsMap[field] =
    //           "Invalid data type: '$field' must be a List for nested list validation";
    //       continue;
    //     }
    //     throw Exception(
    //         "Invalid data type: '$field' must be a List for nested list validation");
    //   }

    //   Map<String, dynamic> listFieldMap = {
    //     for (int i = 0; i < value!.length; i++) i.toString(): value![i]
    //   };

    //   if (rule.childList!.last.isRuleForEachElement == true) {
    //     rule.childList = List.filled(value!.length, rule.childList!.last);
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
      if (!customRegex.hasMatch(value!)) {
        return (field, rule.regex!.$2 ?? "Invalid format");
      }
    }

    // Custom Callback Function Validation
    if (rule.callback != null) {
      bool isValid = rule.callback!.$1(value!);

      if (!isValid) {
        return (field, rule.callback!.$2);
      }
    }

    return error;
  }

  (String, String)? _validateDynamics(
      dynamic value, MapEntry<String, ValidationRules> r, bool isTypeSafety) {
    final String field = r.key;
    final ValidationRules rule = r.value;
    (String, String)? error;

    if (rule.nullable && value == null) {
      return error;
    }

    // Required Validation
    if (rule.required != null) {
      if (value == null) {
        return (field, rule.required!.$2 ?? "$field is required");
      }
      if (rule.required!.$1 && value is String && value.trim().isEmpty) {
        return (
          field,
          rule.required!.$2 ?? "$field is required and should not be empty"
        );
      }
    }

    // Data Type Validation
    if (rule.dataType != null) {
      switch (rule.dataType!.$1) {
        case DataTypes.STRING:
          if (value is! String) {
            return (field, rule.dataType!.$2 ?? "$field must be a string");
          }
          break;

        case DataTypes.NUMBER:
          if (value is! num) {
            return (field, rule.dataType!.$2 ?? "$field must be a number");
          }
          break;

        case DataTypes.BOOLEAN:
          if (value is! bool) {
            return (field, rule.dataType!.$2 ?? "$field must be a boolean");
          }
          break;

        case DataTypes.MAP:
          if (value is! Map<String, dynamic>) {
            return (field, rule.dataType!.$2 ?? "$field must be an object");
          }
          break;

        case DataTypes.LIST:
          if (value is! List<dynamic>) {
            return (field, rule.dataType!.$2 ?? "$field must be a list");
          }
          break;
      }
    }

    // Min Length Validation
    if (rule.minLength != null) {
      if (value.toString().length < rule.minLength!.$1) {
        return (
          field,
          rule.minLength!.$2 ??
              "$field must be at least ${rule.minLength!.$1} characters"
        );
      }
    }

    // Max Length Validation
    if (rule.maxLength != null) {
      if (value.toString().length > rule.maxLength!.$1) {
        return (
          field,
          rule.maxLength!.$2 ??
              "$field must not exceed ${rule.maxLength!.$1} characters"
        );
      }
    }

    // Exact Length Validation
    if (rule.exactLength != null) {
      if (value.toString().length != rule.exactLength!.$1) {
        return (
          field,
          rule.exactLength!.$2 ??
              "$field must be exactly ${rule.exactLength!.$1} characters"
        );
      }
    }

    // Min Number Validation
    if (rule.minNumber != null) {
      if (value is! num) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a number for minimum number validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for minimum number validation");
      }

      if (value < rule.minNumber!.$1) {
        return (
          field,
          rule.minNumber!.$2 ?? "$field must be at least ${rule.minNumber!.$1}"
        );
      }
    }

    // Max Number Validation
    if (rule.maxNumber != null) {
      if (value is! num) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a number for maximum number validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for maximum number validation");
      }

      if (value > rule.maxNumber!.$1) {
        return (
          field,
          rule.maxNumber!.$2 ?? "$field must not exceed ${rule.maxNumber!.$1}"
        );
      }
    }

    // Exact Number Validation
    if (rule.exactNumber != null) {
      if (value is! num) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a number for exact number validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a number for exact number validation");
      }

      if (value != rule.exactNumber!.$1) {
        return (
          field,
          rule.exactNumber!.$2 ??
              "$field must be exactly ${rule.exactNumber!.$1}"
        );
      }
    }

    // Email Validation
    if (rule.validEmail != null) {
      if (value is! String) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a string for email validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for email validation");
      }

      RegExp emailRegex =
          RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
      if (!emailRegex.hasMatch(value)) {
        return (field, rule.validEmail!.$1 ?? "Invalid email format");
      }
    }

    // URL Validation
    if (rule.validUrl != null) {
      if (value is! String) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a string for url validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for url validation");
      }

      RegExp urlRegex = RegExp(
          r"^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$");
      if (!urlRegex.hasMatch(value)) {
        return (field, rule.validUrl!.$1 ?? "Invalid URL format");
      }
    }

    // Valid DateTime Validation
    if (rule.validDate != null) {
      if (value is! String) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a string for datetime validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for datetime validation");
      }

      if (rule.validDate!.$1 == null) {
        RegExp dateTimeRegex = RegExp(
            r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
        if (!dateTimeRegex.hasMatch(value)) {
          return (field, rule.validDate!.$2 ?? "Invalid datetime format");
        }
      } else {
        switch (rule.validDate!.$1!) {
          case DateTimeFormat.DATE:
            RegExp dateRegex =
                RegExp(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$");
            if (!dateRegex.hasMatch(value)) {
              return (field, rule.validDate!.$2 ?? "Invalid date format");
            }
            break;

          case DateTimeFormat.TIME:
            RegExp timeRegex =
                RegExp(r"^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!timeRegex.hasMatch(value)) {
              return (field, rule.validDate!.$2 ?? "Invalid time format");
            }
            break;

          case DateTimeFormat.DATETIME:
            RegExp dateTimeRegex = RegExp(
                r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
            if (!dateTimeRegex.hasMatch(value)) {
              return (field, rule.validDate!.$2 ?? "Invalid datetime format");
            }
            break;
        }
      }
    }

    // In List Validation
    if (rule.inList != null) {
      if (!rule.inList!.$1.contains(value)) {
        return (
          field,
          rule.inList!.$2 ??
              "$field should be one of: ${rule.inList!.$1.join(', ')}"
        );
      }
    }

    // Not In List Validation
    if (rule.notInList != null) {
      if (rule.notInList!.$1.contains(value)) {
        return (
          field,
          rule.notInList!.$2 ??
              "$field must not be one of: ${rule.notInList!.$1.join(', ')}"
        );
      }
    }

    // Nested Map Validation
    if (rule.childMap != null && rule.childMap!.isNotEmpty) {
      if (value is! Map<String, dynamic>) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be an object for nested map validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be an object for nested map validation");
      }

      final isChildValidate =
          _internalValidate({}, value, rule.childMap!, isTypeSafety);
      if (isChildValidate.isNotEmpty) {
        final errorField = '$field.${isChildValidate.keys.first}';
        final errorMsg = isChildValidate.values.first;
        return (errorField, errorMsg);
      }
    }

    // Nested List Validation
    if (rule.childList != null && rule.childList!.isNotEmpty) {
      if (value is! List<dynamic>) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a List for nested list validation"
          );
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
          _internalValidate({}, listFieldMap, listRuleMap, isTypeSafety);

      if (isChildValidate.isNotEmpty) {
        final errorField = '$field.${isChildValidate.keys.first}';
        final errorMsg = isChildValidate.values.first;
        return (errorField, errorMsg);
      }
    }

    // Custom Regex Validation
    if (rule.regex != null) {
      if (value is! String) {
        if (isTypeSafety) {
          return (
            field,
            "Invalid data type: '$field' must be a string for regex validation"
          );
        }
        throw Exception(
            "Invalid data type: '$field' must be a string for regex validation");
      }
      RegExp customRegex = RegExp(rule.regex!.$1);
      if (!customRegex.hasMatch(value)) {
        return (field, rule.regex!.$2 ?? "Invalid format");
      }
    }

    // Custom Callback Function Validation
    if (rule.callback != null) {
      bool isValid = rule.callback!.$1(value);

      if (!isValid) {
        return (field, rule.callback!.$2);
      }
    }
    return null;
  }

  /// Returns all validation errors as a map of field → message.
  ///
  /// Example:
  /// ```dart
  /// {
  ///   "email": "Email is required",
  ///   "age": "Age must be at least 18"
  /// }
  /// ```
  Map<String, String> get getAllErrors => _errorsMap;

  /// Returns only the first validation error as a [MapEntry].
  ///
  /// Useful when you want to show a single error message (e.g., for form UI feedback).
  ///
  /// Example:
  /// ```dart
  /// final error = validator.getError;
  /// print("${error.key} => ${error.value}");
  /// ```
  MapEntry<String, String> get getError => _errorsMap.entries.first;
}
