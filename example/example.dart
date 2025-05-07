import 'package:sirius_backend/sirius_backend.dart';

void main() async {
  final sirius = Sirius();

  // Global Middleware
  sirius.useBefore(LoggerMiddleware());

  // Global Wrapper-Middleware
  sirius.wrap(TimerWrapper());

  // Simple Route
  sirius.get('/hello', (req) async {
    return Response.send({"message": "Hello from Sirius!"});
  });

  // User Routes
  sirius.group('/user', (group) {
    group.post('/create', userController.createUser);
    group.get('/info', userController.getInfo,
        useAfter: [ResponseTimeMiddleware()]);
  });

  // WebSocket route
  sirius.webSocket('/chat', (request, socketConn) {
    final connId = socketConn.getId;
    print("Client connected: $connId");

    // Respond to a custom event
    socketConn.onEvent("ping", (data) {
      print("Received ping: $data");
      socketConn.sendEvent("pong", {"message": "Pong received!", "echo": data});
    });

    // Listen to raw messages (not event-based)
    socketConn.onData((msg) {
      print("Raw message: $msg");
      socketConn.sendData("Echo: $msg");
    });

    // Handle disconnection
    socketConn.onDisconnect(() {
      print("Client disconnected: $connId");
    });
  });

  // Start the server
  sirius.start(
      port: 3333,
      callback: (server) {
        print("Server is running");
      });

  // Server will restart on save
  fileWatcher("example/example.dart", callback: () async {
    await sirius.close();
  });
}

// Controller Class
UserController userController = UserController();

class UserController {
  Future<Response> createUser(Request request) async {
    final validator = Validator(request.getAllFields, {
      'name': ValidationRules(
        required: required(message: "Name is required"),
        minLength: minLength(3),
      ),
      'age': ValidationRules(
        required: required(),
        dataType: dataType(DataTypes.NUMBER),
        minNumber: minNumber(18),
      ),
    });

    if (!validator.validate()) {
      return Response.send(validator.getAllErrors, statusCode: 400);
    }

    return Response.send({
      "message": "User created",
      "data": request.getAllFields,
    });
  }

  Future<Response> getInfo(Request request) async {
    return Response.next();
  }
}

// Logger Middleware
class LoggerMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    print("[LOG] ${request.method} ${request.rawHttpRequest.uri.path}");
    return Response.next();
  }
}

// Response Time Middleware
class ResponseTimeMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    print(
        "${request.method} ${request.rawHttpRequest.uri.path} ${DateTime.now()}");
    return Response.send({
      "name": "Alice",
      "age": 25,
    });
  }
}

// Timer Wrapper-Middleware
class TimerWrapper extends Wrapper {
  @override
  Future<Response> handle(
    Request request,
    Future<Response> Function() nextHandler,
  ) async {
    final start = DateTime.now();
    final response = await nextHandler();
    final end = DateTime.now();
    print(
        "[TIMER] Request processed in ${end.difference(start).inMilliseconds}ms");

    response.addHeader("Content-Type", "application/json");
    return response;
  }
}
