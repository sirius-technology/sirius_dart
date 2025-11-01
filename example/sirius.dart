import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.post('test', (req) async {
    return Response.sendJson({
      'hasBody': req.hasBody,
      'body': req.getBody,
    });
  });

  // app.get('file', (req) async {
  //   return Response.sendFile(
  //       File('/Users/someshsahu/_Beaming_India/_PROJECTS/VEDASAR/vedasar.png'),
  //       inline: true);
  // });

  app.start(callback: (server) {
    print("Server is running");
  });
}
