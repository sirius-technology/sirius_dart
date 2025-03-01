import 'package:sirius/sirius.dart';

import 'controllers/user_controller.dart';

Future<void> main() async {
  DatabaseConfig.driver = DatabaseDrivers.MYSQL;
  DatabaseConfig.host = "localhost";
  DatabaseConfig.port = 3306;
  DatabaseConfig.user = "root";
  DatabaseConfig.password = "Somu1999";
  DatabaseConfig.database = "dart_backend";

  await DatabaseConfig.initialize();

  Server server = Server();

  server.group("api", (route) {
    route.post("addUser", userController.addUser);
    route.get("getAllUsers", userController.getAllUsers);
    route.post("getUser", userController.getUser);
    route.delete("deleteUser", userController.deleteUser);
    // route.put("updateUser", userController.updateUser);
  });

  server.start();
}
