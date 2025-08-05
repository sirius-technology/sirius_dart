import 'package:sirius_backend/sirius_backend.dart';

void main() {
  Sirius app = Sirius();

  app.wrap(corsHandler());

  app.get('get', (req) async {
    return Response.send('Apis is working');
  });

  app.start(callback: (server) {
    print("Server is running");
  });
}
