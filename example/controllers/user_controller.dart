import 'package:sirius/sirius.dart';

import '../models/user_model.dart';

UserController userController = UserController();

class UserController {
  Future<Response> addUser(Request r) async {
    UserModel userModel = UserModel();

    userModel.name = r.jsonValue("name");
    userModel.email = r.jsonValue("email");
    userModel.age = r.jsonValue("age");

    int? id = await userModel.insert();

    return Response({"status": true, "data": id});
  }
}
