import 'package:sirius_backend/sirius_backend.dart';

void main() {
  var r = QueryBuilder("users")
      .where("column1", "value1")
      .where("column2", "value2")
      .where("column3", "value3")
      .getLast();

  print("QUERY -->> ${r.query}");
  print("VALUES -->> ${r.values}");
}
