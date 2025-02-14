import 'package:mysql1/mysql1.dart';
import 'package:sirius/src/databases/database_config.dart';

final ConnectionSettings setting = ConnectionSettings(
  host: DatabaseConfig.host,
  port: DatabaseConfig.port,
  user: DatabaseConfig.user,
  password: DatabaseConfig.password,
  db: DatabaseConfig.database,
);

Future<MySqlConnection> connectMySql() async {
  return await MySqlConnection.connect(setting);
}

Future<void> closeMySql(MySqlConnection conn) async {
  await conn.close();
}
