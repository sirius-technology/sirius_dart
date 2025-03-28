import 'package:sirius/sirius.dart';
import 'validation_rules.dart';

class Validator {
  Validator(Request request, this.rules) {
    _requestMap = request.jsonBody;
  }

  Map<String, dynamic>? _requestMap;
  final Map<String, ValidationRules> rules;
  final Map<String, String> _errorsMap = {};

  bool validate() {
    _errorsMap.clear();

    if (_requestMap == null) {
      throw Exception("Request body is missing or not in JSON format.");
    }

    for (MapEntry<String, ValidationRules> val in rules.entries) {
      var value = _requestMap![val.key];
      String field = val.key;
      ValidationRules rule = val.value;

      // Required Validation
      if (rule.required != null && value == null) {
        _errorsMap[field] = rule.required!.message ?? "$field is required";
        continue;
      }

      // Filled Validation
      if (rule.filled != null && value.runtimeType == String && value.isEmpty) {
        _errorsMap[field] =
            rule.filled!.message ?? "$field should not be empty";
        continue;
      }

      // Data Type Validation
      if (rule.dataType != null) {
        switch (rule.dataType!.type) {
          case DataTypes.STRING:
            if (value is! String) {
              _errorsMap[field] =
                  rule.dataType!.message ?? "$field must be a string";
              continue;
            }
            break;

          case DataTypes.NUMBER:
            if (value is! num) {
              _errorsMap[field] =
                  rule.dataType!.message ?? "$field must be a number";
              continue;
            }
            break;

          case DataTypes.BOOLEAN:
            if (value is! bool) {
              _errorsMap[field] =
                  rule.dataType!.message ?? "$field must be a boolean";
              continue;
            }
            break;
        }
      }

      // Min Length Validation
      if (rule.minLength != null) {
        if (value.toString().length < rule.minLength!.length) {
          _errorsMap[field] = rule.minLength!.message ??
              "$field must be at least ${rule.minLength!.length} characters";
          continue;
        }
      }

      // Max Length Validation
      if (rule.maxLength != null) {
        if (value.toString().length > rule.maxLength!.length) {
          _errorsMap[field] = rule.maxLength!.message ??
              "$field must not exceed ${rule.maxLength!.length} characters";
          continue;
        }
      }

      // Exact Length Validation
      if (rule.exactLength != null) {
        if (value.toString().length != rule.exactLength!.length) {
          _errorsMap[field] = rule.exactLength!.message ??
              "$field must be exactly ${rule.exactLength!.length} characters";
          continue;
        }
      }

      // Min Number Validation
      if (rule.minNumber != null) {
        if (value is! num) {
          throw Exception("Invalid data type: '$field' must be a number.");
        }

        if (value < rule.minNumber!.number) {
          _errorsMap[field] = rule.minNumber!.message ??
              "$field must be at least ${rule.minNumber!.number}";
          continue;
        }
      }

      // Max Number Validation
      if (rule.maxNumber != null) {
        if (value is! num) {
          throw Exception("Invalid data type: '$field' must be a number.");
        }

        if (value > rule.maxNumber!.number) {
          _errorsMap[field] = rule.maxNumber!.message ??
              "$field must not exceed ${rule.maxNumber!.number}";
          continue;
        }
      }

      // Exact Number Validation
      if (rule.exactNumber != null) {
        if (value is! num) {
          throw Exception("Invalid data type: '$field' must be a number.");
        }

        if (value != rule.exactNumber!.number) {
          _errorsMap[field] = rule.exactNumber!.message ??
              "$field must be exactly ${rule.exactNumber!.number}";
          continue;
        }
      }

      // Email Validation
      if (rule.validEmail != null) {
        if (value is! String) {
          throw Exception("Invalid data type: '$field' must be a string.");
        }

        RegExp emailRegex =
            RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
        if (!emailRegex.hasMatch(value)) {
          _errorsMap[field] =
              rule.validEmail!.message ?? "Invalid email format";
          continue;
        }
      }

      // URL Validation
      if (rule.validUrl != null) {
        if (value is! String) {
          throw Exception("Invalid data type: '$field' must be a string.");
        }

        RegExp urlRegex = RegExp(
            r"^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([\/\w .-]*)*\/?$");
        if (!urlRegex.hasMatch(value)) {
          _errorsMap[field] = rule.validUrl!.message ?? "Invalid URL format";
          continue;
        }
      }

      // Valid DateTime Validation
      if (rule.validDate != null) {
        if (value is! String) {
          throw Exception("Invalid data type: '$field' must be a string.");
        }

        if (rule.validDate!.format == null) {
          RegExp dateTimeRegex = RegExp(
              r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
          if (!dateTimeRegex.hasMatch(value)) {
            _errorsMap[field] =
                rule.validDate!.message ?? "Invalid datetime format";
            continue;
          }
        } else {
          switch (rule.validDate!.format!) {
            case DateTimeFormat.DATE:
              RegExp dateRegex =
                  RegExp(r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$");
              if (!dateRegex.hasMatch(value)) {
                _errorsMap[field] =
                    rule.validDate!.message ?? "Invalid date format";
                continue;
              }
              break;

            case DateTimeFormat.TIME:
              RegExp timeRegex =
                  RegExp(r"^(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
              if (!timeRegex.hasMatch(value)) {
                _errorsMap[field] =
                    rule.validDate!.message ?? "Invalid time format";
                continue;
              }
              break;

            case DateTimeFormat.DATETIME:
              RegExp dateTimeRegex = RegExp(
                  r"^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]) (?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d{1,6})?$");
              if (!dateTimeRegex.hasMatch(value)) {
                _errorsMap[field] =
                    rule.validDate!.message ?? "Invalid datetime format";
                continue;
              }
              break;
          }
        }
      }

      // Custom Regex Validation
      if (rule.regex != null) {
        if (value is! String) {
          throw Exception("Invalid data type: '$field' must be a string.");
        }
        RegExp customRegex = RegExp(rule.regex!.pattern);
        if (!customRegex.hasMatch(value)) {
          _errorsMap[field] = rule.regex!.message ?? "Invalid format";
          continue;
        }
      }

      // Custom Callback Function Validation
      if (rule.callback != null) {
        bool isValid = rule.callback!.callback(value);

        if (!isValid) {
          _errorsMap[field] = rule.callback!.message;
          continue;
        }
      }
    }

    return _errorsMap.isEmpty;
  }

  Map get allErrors => _errorsMap;
}
