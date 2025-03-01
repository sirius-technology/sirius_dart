class BaseController {
  Map<String, dynamic> baseResponse(
      {required bool status, required dynamic data}) {
    return {
      "status": status,
      "data": data,
    };
  }
}
