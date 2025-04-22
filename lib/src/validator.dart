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

        if (rule.childList!.last.isRuleForEachElement == true) {
          rule.childList = List.filled(value.length, rule.childList!.last);
        }

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
