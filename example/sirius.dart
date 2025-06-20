import 'package:sirius_backend/sirius_backend.dart';

void main() {
  var r = QueryBuilder("users").where("column1", "value1").update(
      {"location": RawSql("ST_GeomFromText('POINT(72.8777 19.0760)')")});

  print("QUERY -->> ${r.query}");
  print("VALUES -->> ${r.values}");
}
