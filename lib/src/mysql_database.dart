import 'package:mysql1/mysql1.dart';

final ConnectionSettings setting = ConnectionSettings(
  host: "localhost",
  port: 3306,
  user: "root",
  password: "Somu1999",
  db: "dart_backend",
);

Future<MySqlConnection> connectMySql() async {
  return await MySqlConnection.connect(setting);
}

Future<void> closeMySql(MySqlConnection conn) async {
  await conn.close();
}
