import 'dart:io';

import 'package:sirius_backend/sirius_backend.dart';

Future<void> main() async {
  Sirius app = Sirius();

  app.post('test', (req) async {
    final rules = {
      'name': ValidationRules(required: required()),
      'age_list': ValidationRules(
        required: required(),
        dataType: dataType(DataTypes.LIST),
        childList: ValidationRules(
                required: required(), dataType: dataType(DataTypes.STRING))
            .forEachElement(),
      ),
      'age_map': ValidationRules(childMap: {
        'age_1': ValidationRules(required: required(), childMap: {
          'age_child_2': ValidationRules(required: required()),
        })
      })
    };

    final validator = Validator(req, rules);

    if (!validator.validate()) {
      return Response.sendJson(validator.getAllErrors, statusCode: 422);
    }

    return Response.sendJson({
      'path': req.allPathVariables,
      'query': req.allQueryParams,
      'body': req.getBody,
    });
  });

  app.get('file', (req) async {
    return Response.sendFile(
        File('/Users/someshsahu/_Beaming_India/_PROJECTS/VEDASAR/vedasar.png'),
        inline: true);
  });

  app.start(callback: (server) {
    print("Server is running");
  });
}
