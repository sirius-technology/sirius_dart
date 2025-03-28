// import 'package:mysql1/mysql1.dart';
// import 'package:sirius/src/query_builder.dart';
// import 'helpers/logging.dart';
// import 'databases/mysql_database.dart';

// abstract class Model extends QueryBuilder {
//   Model({required this.table}) : super(table);

//   String table;
//   int? id;

//   Map<String, dynamic> toMap();

//   Future<Map<String, dynamic>?> findById(int id) async {
//     MySqlConnection conn = await connectMySql();
//     findByIdQuery(id).build();
//     Results result = await conn.query(query, [id]);
//     conn.close();

//     if (result.isEmpty) {
//       logError("id is not exist");
//       return null;
//     }

//     Map<String, dynamic> row = result.first.fields;

//     return row;
//   }

//   Future<List<Map<String, dynamic>>?> findAll() async {
//     MySqlConnection conn = await connectMySql();
//     String qry = "SELECT * FROM $table";
//     Results result = await conn.query(qry);
//     conn.close();

//     if (result.isEmpty) {
//       return [];
//     }

//     List<Map<String, dynamic>> data = [];
//     for (ResultRow row in result) {
//       data.add(row.fields);
//     }

//     return data;
//   }

//   Future<int?> insert() async {
//     Map<String, dynamic> data = toMap();

//     if (id == null) {
//       String columns = data.keys.join(", ");
//       String placeHolders = List.filled(data.length, "?").join(", ");

//       MySqlConnection conn = await connectMySql();

//       Results result = await conn.query(
//           "INSERT INTO $table ($columns) VALUES ($placeHolders)",
//           data.values.toList());

//       conn.close();

//       id = result.insertId;
//       return id;
//     } else {
//       String setClause = data.keys.map((key) => '$key = ?').join(", ");

//       MySqlConnection conn = await connectMySql();

//       await conn.query("UPDATE $table SET $setClause WHERE id = ?",
//           data.values.toList()..add(id));

//       conn.close();

//       return id;
//     }
//   }

//   Future<bool> update(int id) async {
//     Map<String, dynamic> data = toMap();

//     data.removeWhere((key, value) => value == null);

//     if (data.isEmpty) {
//       logError("No data to update");
//       return false;
//     }

//     String clasue = data.keys.map((key) => "$key = ?").join(", ");

//     MySqlConnection conn = await connectMySql();

//     Results results = await conn.query("UPDATE $table SET $clasue WHERE id = ?",
//         data.values.toList()..add(id));

//     conn.close();

//     if (results.affectedRows == 0) {
//       logError("0 Rows affected.");
//       return false;
//     }
//     return true;
//   }

//   Future<List<Map<String, dynamic>>?> getAll() async {
//     MySqlConnection conn = await connectMySql();

//     Results results = await conn.query(query, values);

//     conn.close();

//     return results.map((e) => e.fields).toList();
//   }

//   Future<bool> delete(int id) async {
//     MySqlConnection conn = await connectMySql();

//     Results results = await conn.query("DELETE FROM $table WHERE id = ?", [id]);

//     conn.close();

//     if (results.affectedRows == 0) {
//       logError("0 Rows affected.");
//       return false;
//     }
//     return true;
//   }
// }
