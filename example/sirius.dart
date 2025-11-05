import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.post('test', (req) async {
    final rules = {
      'name': ValidationRules(
          callback: callback((val) {
        print('value : $val');
        return false;
      }, message: 'This is a message'))
    };

    final validator = Validator(req, rules);

    if (!validator.validate()) {
      return Response.sendJson({
        'errors': validator.getError.value,
      }, statusCode: 400);
    }

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
