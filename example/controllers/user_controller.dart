import 'package:sirius/sirius.dart';
import 'package:sirius/src/validator.dart';

import '../models/user_model.dart';
import 'base_controller.dart';

UserController userController = UserController();

class UserController extends BaseController {
  Future<Response> addUser(Request r) async {
    UserModel userModel = UserModel();

    userModel.name = r.jsonValue("name");
    userModel.email = r.jsonValue("email");
    userModel.age = r.jsonValue("age");

    int? id = await userModel.insert();

    return Response({"status": true, "data": id});
  }

  Future<Response> getAllUsers(Request r) async {
    UserModel userModel = UserModel();

    List<Map<String, dynamic>>? userList = await userModel.findAll();

    return Response(baseResponse(status: true, data: userList));
  }

  Future<Response> getUser(Request r) async {
    Map<String, List<String>> rules = {
      "user_id": ["REQUIRED"]
    };

    Validator validator = Validator(r, rules);

    if (!validator.validate()) {
      return Response(baseResponse(status: false, data: validator.allErrors));
    }

    int userId = r.jsonValue("user_id");

    UserModel userModel = UserModel();

    Map<String, dynamic>? user = await userModel.findById(userId);

    return Response(baseResponse(status: true, data: user));
  }

  Future<Response> deleteUser(Request r) async {
    Map<String, List<String>> rules = {
      "user_id": ["REQUIRED"]
    };

    Validator validator = Validator(r, rules);

    if (!validator.validate()) {
      return Response(baseResponse(status: false, data: validator.allErrors));
    }

    int userId = r.jsonValue("user_id");

    UserModel userModel = UserModel();

    bool isDeleted = await userModel.delete(userId);

    return Response(baseResponse(status: isDeleted, data: isDeleted));
  }

  // Future<Response> updateUser(Request request) async {
  //   Map<String, List<String>> rules = {
  //     "user_id": ["REQUIRED"]
  //   };

  //   Validator validator = Validator(request, rules);

  //   if (!validator.validate()) {
  //     return Response(baseResponse(status: false, data: validator.allErrors));
  //   }

  //   int userId = request.jsonValue("user_id");

  //   UserModel userModel = UserModel();

  //   userModel.age = 11;
  //   userModel.name = "John Doe";

  //   bool isUpdate = await userModel.update(userId);

  //   userModel.select().

  //   return Response(baseResponse(status: true, data: isUpdate));
  // }
}
