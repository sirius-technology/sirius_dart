import 'package:sirius_backend/sirius_backend.dart';

void main() {
  var r = QueryBuilder("users").update({"name": "somu", "age": null});

  print("QUERY -->> ${r.query}");
  print("VALUES -->> ${r.values}");
}
