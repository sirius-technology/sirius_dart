import 'dart:io';

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
        } on SocketException catch (e) {
          logError("MySQL connection failed 1 : $e");
          return false;
        } on MySqlException catch (e) {
          logError("MySQL connection failed 2 : $e");
          return false;
        } catch (e) {
          logError("MySQL connection failed 3 : $e");
          return false;
        }
      case DatabaseDrivers.SQLITE:
        logWarning("🚀 SQLite is coming soon.");
        return false;
      case DatabaseDrivers.POSTGRESQL:
        logWarning("🚀 PostgreSQL is coming soon.");
        return false;
    }
  }
}
