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

  server.group("/prefix", (route) {
    route.group("/suffix", (route2) {
      route2.get("/user", userController.addUser);
      route2.post("/user", userController.addUser);
    });
  });

  server.post("/user", userController.addUser);
  server.get("/user", userController.addUser);
  // server.get("/user", userController.addUser);

  server.start();
}
