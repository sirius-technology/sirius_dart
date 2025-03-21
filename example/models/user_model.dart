import 'package:sirius/sirius.dart';

class UserModel extends Model {
  UserModel() : super(table: "users");

  @override
  int? id;
  String? name;
  String? email;
  int? age;

  @override
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "age": age,
    };
  }
}
