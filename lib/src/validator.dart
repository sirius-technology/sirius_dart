import 'request.dart';

class Validator {
  Validator(this.request, this.rules);
  Request request;
  Map<String, List<String>> rules;
  final Map _errors = {};

  bool validate() {
    Map<String, dynamic> data = request.jsonBody ?? {};

    for (MapEntry val in rules.entries) {
      List<String> ruleList = val.value;

      if (ruleList.contains("REQUIRED") &&
          (data.keys.contains(val.key) == false)) {
        _errors[val.key] = "${val.key} is required";
        continue;
      }

      // if (data.containsKey(val.key)) {
      //   dynamic value = data[val.key];

      //   if (ruleList.contains("STRING") && (value is String) == false) {
      //     _errors[val.key] = "${val.key} must be a string";
      //   }
      // }
    }
    return _errors.isEmpty;
  }

  Map get allErrors => _errors;
}
