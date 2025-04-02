import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.post("/", (Request request) async {
    Map<String, dynamic> data = {
      "name": "Somesh",
      "date": DateTime.now(),
    };

    return Response().send(data);
  });

  app.start(
    port: 9000,
    callback: (server) {
      print("Server is running");
    },
  );

  await fileWatcher("example/sirius_example.dart", callback: () {
    app.close();
  });
}
