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
  (String?,)? required;

  /// Field must not be empty.
  (String?,)? filled;

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

  /// Field must match the given regular expression.
  (String, String?)? regex;

  /// Custom validation using a callback.
  (bool Function(dynamic value), String)? callback;

  ValidationRules({
    this.required,
    this.filled,
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
(String?,) required([String? message]) => (message,);

/// Requires the field to be non-empty.
///
/// Example:
/// ```dart
/// filled("Please fill this field")
/// ```
(String?,) filled([String? message]) => (message,);

/// Validates the data type.
///
/// Example:
/// ```dart
/// dataType(DataTypes.STRING, "Must be a string")
/// ```
(DataTypes, String?) dataType(DataTypes type, [String? message]) =>
    (type, message);

/// Validates minimum string length.
///
/// Example:
/// ```dart
/// minLength(3, "At least 3 characters required")
/// ```
(int, String?)? minLength(int value, [String? message]) => (value, message);

/// Validates maximum string length.
///
/// Example:
/// ```dart
/// maxLength(10, "At most 10 characters allowed")
/// ```
(int, String?)? maxLength(int value, [String? message]) => (value, message);

/// Validates exact string length.
///
/// Example:
/// ```dart
/// exactLength(5, "Must be 5 characters")
/// ```
(int, String?)? exactLength(int value, [String? message]) => (value, message);

/// Validates minimum numeric value.
///
/// Example:
/// ```dart
/// minNumber(1, "Value must be at least 1")
/// ```
(int, String?)? minNumber(int value, [String? message]) => (value, message);

/// Validates maximum numeric value.
///
/// Example:
/// ```dart
/// maxNumber(100, "Cannot exceed 100")
/// ```
(int, String?)? maxNumber(int value, [String? message]) => (value, message);

/// Validates exact numeric value.
///
/// Example:
/// ```dart
/// exactNumber(42, "Value must be 42")
/// ```
(int, String?)? exactNumber(int value, [String? message]) => (value, message);

/// Validates email format.
///
/// Example:
/// ```dart
/// validEmail("Invalid email format")
/// ```
(String?,) validEmail([String? message]) => (message,);

/// Validates URL format.
///
/// Example:
/// ```dart
/// validUrl("Invalid URL")
/// ```
(String?,) validUrl([String? message]) => (message,);

/// Validates date format.
///
/// Example:
/// ```dart
/// validDate(DateTimeFormat.DATETIME, "Invalid date")
/// ```
(DateTimeFormat, String?)? validDate([
  DateTimeFormat format = DateTimeFormat.DATETIME,
  String? message,
]) =>
    (format, message);

/// Validates a custom regular expression.
///
/// Example:
/// ```dart
/// regex(r'^\\d{4}\$', "Must be a 4-digit number")
/// ```
(String, String?)? regex(String pattern, [String? message]) =>
    (pattern, message);

/// Custom validation callback.
///
/// Example:
/// ```dart
/// callback((value) => value == "admin", "Only 'admin' is allowed")
/// ```
(bool Function(dynamic value), String) callback(
  bool Function(dynamic value) validate,
  String message,
) =>
    (validate, message);
