import 'package:sirius/sirius.dart';

import 'middlewares/first_middleware.dart';
import 'middlewares/second_middleware.dart';

Future<void> main() async {
  DatabaseConfig.driver = DatabaseDrivers.MYSQL;
  DatabaseConfig.host = "localhost";
  DatabaseConfig.port = 3306;
  DatabaseConfig.user = "root";
  DatabaseConfig.password = "Somu1999";
  DatabaseConfig.database = "dart_backend";

  await DatabaseConfig.initialize();

  Sirius app = Sirius();

  app.use(FirstMiddleware());

  app.get("/api", (Request r) async {
    return Response().send({"b": 0});
  });

  app.group("user", (route) {
    route.use(SecondMiddleware());
    route.get("get", (Request r) async {
      return Response().send({"user": 0});
    });
  });

  app.start(
      port: 9000,
      callback: () {
        print("Server is running port 9000");
      });

  await fileWatcher("example/sirius_example.dart", callback: () {
    app.close();
  });
}
