import 'package:postgres/postgres.dart';
import 'package:sirius/sirius.dart';

final Endpoint _postgresqlSetting = Endpoint(
    host: DatabaseConfig.host,
    port: DatabaseConfig.port,
    database: DatabaseConfig.database,
    username: DatabaseConfig.user,
    password: DatabaseConfig.password);

Future<Connection> connectPostgresql() async {
  return await Connection.open(_postgresqlSetting);
}
