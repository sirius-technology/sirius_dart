import 'package:mysql1/mysql1.dart';
import 'package:sirius/src/databases/mysql_database.dart';
import 'package:sirius/src/enums/database_drivers.dart';
import 'package:sirius/src/logging.dart';

class DatabaseConfig {
  static late DatabaseDrivers driver;
  static late String host;
  static late int port;
  static late String user;
  static late String password;
  static late String database;

  static Future<bool> initialize() async {
    switch (driver) {
      case DatabaseDrivers.MYSQL:
        try {
          MySqlConnection conn = await connectMySql();
          logSuccess("MySQL connection established. 🚀");
          conn.close();
          return true;
        } catch (e) {
          logError("MySQL connection failed : $e");
          return false;
        }
      case DatabaseDrivers.SQLITE:
        logWarning("🚀 SQLite is coming soon.");
        return false;
      case DatabaseDrivers.POSTGRESQL:
        logWarning("🚀 PostgreSQL is coming soon.");
        return false;
      // try {
      //   Connection conn = await connectPostgresql();
      //   logSuccess("PostgreSQL connection established. 🚀");
      //   conn.close();
      //   return true;
      // } catch (e) {
      //   logError("PostgreSQL connection failed : $e");
      //   return false;
      // }
    }
  }
}
