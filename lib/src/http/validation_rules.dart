import '../enums/data_types.dart';
import '../enums/date_time_formats.dart';

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
  List<ValidationRules>? childList;

  /// Field must match the given regular expression.
  (String, String?)? regex;

  /// Custom validation using a callback.
  (bool Function(dynamic value), String)? callback;

  /// Marks that the rule applies to each element in a list.
  ///
  /// Used internally with [childList] to apply the same rule to each item.
  bool isRuleForEachElement = false;

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

  /// Helper to apply the rule to each element of a list.
  ///
  /// Used when the same rule needs to apply to **every element** inside a list field.
  /// This is especially useful when validating a list of primitive types like `int`, `String`, etc.
  ///
  /// Internally sets the `isRuleForEachElement` flag to true so that the validator
  /// can apply the same rule to all elements dynamically.
  ///
  /// ### Example:
  /// ```dart
  /// Map<String, ValidationRules> rules = {
  ///   "ids": ValidationRules(
  ///     dataType: dataType(DataTypes.LIST),
  ///     childList: ValidationRules(
  ///       required: required(),
  ///       dataType: dataType(DataTypes.NUMBER),
  ///     ).forEachElement(), // ✅ Applies the rule to all items in the list
  ///   ),
  /// };
  /// ```
  ///
  /// In this example, all items in the `ids` list will be required and must be numbers.
  List<ValidationRules> forEachElement() {
    isRuleForEachElement = true;
    return [this];
  }
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
