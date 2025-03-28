import 'enums/data_types.dart';
import 'enums/date_time_formats.dart';

class ValidationRules {
  ({String? message})? required;
  ({String? message})? filled;
  ({DataTypes type, String? message})? dataType;
  ({int length, String? message})? minLength;
  ({int length, String? message})? maxLength;
  ({int length, String? message})? exactLength;
  ({int number, String? message})? minNumber;
  ({int number, String? message})? maxNumber;
  ({int number, String? message})? exactNumber;
  ({String? message})? validEmail;
  ({String? message})? validUrl;
  ({DateTimeFormat? format, String? message})? validDate;
  ({String pattern, String? message})? regex;
  ({bool Function(dynamic value) callback, String message})? callback;

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
