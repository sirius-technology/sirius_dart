import 'enums/data_types.dart';
import 'enums/date_time_formats.dart';

class ValidationRules {
  (String?,)? required;
  (String?,)? filled;
  (DataTypes, String?)? dataType;
  (int, String?)? minLength;
  (int, String?)? maxLength;
  (int, String?)? exactLength;
  (int, String?)? minNumber;
  (int, String?)? maxNumber;
  (int, String?)? exactNumber;
  (String?,)? validEmail;
  (String?,)? validUrl;
  (DateTimeFormat?, String?)? validDate;
  (String, String?)? regex;
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

(String?,) required([String? message]) {
  return (message,);
}

(String?,) filled([String? message]) {
  return (message,);
}

(DataTypes, String?) dataType(DataTypes type, [String? message]) {
  return (type, message);
}

(int, String?)? minLength(int minLength, [String? message]) {
  return (minLength, message);
}

(int, String?)? maxLength(int maxLength, [String? message]) {
  return (maxLength, message);
}

(int, String?)? exactLength(int exactLength, [String? message]) {
  return (exactLength, message);
}

(int, String?)? minNumber(int minNumber, [String? message]) {
  return (minNumber, message);
}

(int, String?)? maxNumber(int maxNumber, [String? message]) {
  return (maxNumber, message);
}

(int, String?)? exactNumber(int exactNumber, [String? message]) {
  return (exactNumber, message);
}

(String?,) validEmail([String? message]) {
  return (message,);
}

(String?,) validUrl([String? message]) {
  return (message,);
}

(DateTimeFormat, String?)? validDate(
    [DateTimeFormat format = DateTimeFormat.DATETIME, String? message]) {
  return (format, message);
}

(String, String?)? regex(String pattern, [String? message]) {
  return (pattern, message);
}

(bool Function(dynamic value), String) callback(
    bool Function(dynamic value) callback, String message) {
  return (callback, message);
}
