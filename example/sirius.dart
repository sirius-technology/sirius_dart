import 'dart:io';
import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  app.post("add", (Request request) async {
    File file = request.getFile("image")!;

    final uploadDir = Directory('uploads');
    if (!uploadDir.existsSync()) {
      uploadDir.createSync(recursive: true);
    }

    final newPath = 'uploads/image.png';

    final newFile = await file.rename(newPath);

    return Response.sendJson(newFile.path);
  });

  app.start(callback: (HttpServer server) {
    print("Server is running");
  });

  // fileWatcher("example/sirius.dart", callback: () {
  //   app.close();
  // });
}
