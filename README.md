# Sirius ⚡ — A Lightweight Dart Backend Framework

Sirius is a lightweight, expressive, and fast HTTP & WebSocket backend framework built entirely with Dart.  
It features powerful routing, composable middleware, validation, and wrapper lifecycle hooks

---

## 🚀 Features

- ⚡ Simple, expressive routing (GET, POST, PUT, PATCH, DELETE)
- 🔁 Middleware support (before & after)
- 🧱 Wrapper middleware `.wrap()` for lifecycle-level logic (timing, logging, etc.)
- 🔀 Grouped routes
- 🔐 Validation with nested objects and list support
- 🌐 WebSocket routing support
- 💡 `dart:io` based performance

---

## 📦 Installation

```yaml
dependencies:
  sirius_backend: ^2.3.2
```

Then run:

```bash
dart pub get
```

---

## 🛠️ Basic Usage

```dart
import 'package:sirius_backend/sirius_backend.dart';

void main() async {
  final sirius = Sirius();

  sirius.get('/hello', (req) async {
    return Response.send({'message': 'Hello from Sirius!'});
  });

  await sirius.start(port: 3000);
}
```

---

## 🌐 Routing

```dart
sirius.get('/users', userController.getUsersHandler);
sirius.post('/users', userController.createUserHandler);
sirius.put('/users/:id', userController.updateUserHandler);
sirius.delete('/users/:id', userController.deleteUserHandler);
```

### Grouped Routes

```dart
sirius.group('/api', (router) {
  router.get('/status', (req) async => Response.send({'ok': true}));
});
```

---

## 🧩 Middleware

### Global Middleware

```dart
sirius.useBefore(AuthMiddleware().handle);
sirius.useAfter(LoggerMiddleware().handle);
```

### Route Middleware

```dart
sirius.get('/profile', (req) async => Response.send('Profile'),
  useBefore: [AuthMiddleware().handle],
  useAfter: [LoggerMiddleware().handle],
);
```

### Example Middleware

```dart
class AuthMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    final token = request.headerValue('authorization');
    if (token == 'valid-token') {
      request.passData = {'userId': 123};
      return Response.next();
    }
    return Response.send({'error': 'Unauthorized'}, statusCode: 401);
  }
}
```

---

## 🌀 Wrapper Middleware (NEW in 2.0)

Wrappers allow full control around the lifecycle of a route.

```dart
class TimerWrapper extends Wrapper {
  @override
  Future<Response> handle(Request request, Future<Response> Function() nextHandler) async {
    final start = DateTime.now();
    final response = await nextHandler();
    final end = DateTime.now();
    print("Duration: ${end.difference(start)}");
    return response;
  }
}
```

Register wrapper globally:

```dart
sirius.wrap(TimerWrapper().handle);
```

Or for a single route:

```dart
sirius.get('/dashboard', controller.dashboardHandler, wrap: [TimerWrapper().handle]);
```

---

## 🧾 Request Object

```dart
final id = request.pathVariable('id');
final name = request.jsonValue('name');
final headers = request.headers;
final method = request.method;
final userData = request.receiveData; // Passed via middleware
```

---

## 🧭 Request Lifecycle Flow

```
Incoming Request
  └── Global Wrapper (Entry)
      └── Route Wrapper (Entry)
          └── Global Before Middleware(s)
              └── Route Before Middleware(s)
                  └── Route Handler
                      └── Route After Middleware(s)
                          └── Global After Middleware(s)
                              └── Route Wrapper (Exit)
                                  └── Global Wrapper (Exit)
                                      └── Response Sent
```

```
1️⃣ Incoming Request
    ↓
2️⃣ Global Wrapper (Entry)
    ↓
3️⃣ Route Wrapper (Entry)
    ↓
4️⃣ Global Middlewares (before)
    ↓
5️⃣ Route Middlewares (before)
    ↓
6️⃣ Route Handler (your main logic)
    ↓
7️⃣ Route Middlewares (after)
    ↓
8️⃣ Global Middlewares (after)
    ↓
9️⃣ Route Wrapper (Exit)
    ↓
🔟 Global Wrapper (Exit)
    ↓
🟢 Response Sent
```

---

## ✅ Validation

### Basic Validation

```dart
final validator = Validator(request.getAllFields, {
  'name': ValidationRules(required: required(message: "Name is required")),
  'age': ValidationRules(minNumber: minNumber(18)),
});

if (!validator.validate()) {
  return Response.send(validator.getAllErrors, statusCode: 400);
}
```

### Nested Object Validation

```dart
'address': ValidationRules(
  dataType: dataType(DataTypes.MAP),
  childMap: {
    'street': ValidationRules(required: required()),
    'zip': ValidationRules(minLength: minLength(5)),
  },
)
```

### List Validation

```dart
'items': ValidationRules(
  dataType: dataType(DataTypes.LIST),
  childList: [
    ValidationRules(required: required(message: "Item is required")),
  ],
)
```

### Validate Every List Element with Same Rules

```dart
'ids': ValidationRules(
  dataType: dataType(DataTypes.LIST),
  childList: ValidationRules(
    required: required(),
    dataType: dataType(DataTypes.NUMBER),
  ).forEachElement(),
)
```

---

## 📤 Response API

```dart
return Response.send({"message": "Success"});
return Response.send({"error": "Unauthorized"}, statusCode: 401);
return Response.sendJson({"error": "Unauthorized"}, statusCode: 401);
return Response.next(); // To continue in middleware/chain
```

You can also override headers:

```dart
return Response.send({'ok': true}, overrideHeaders: (headers) {
  headers.set('x-powered-by', 'Sirius');
});
```

---

## 🔄 WebSocket Support

```dart
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
```

---

## 🧱 Advanced Usage: Route Composition

```dart
sirius.get('/secure-data',
  secureDataHandler,
  useBefore: [AuthMiddleware().handle],
  useAfter: [LoggerMiddleware().handle],
  wrap: [TimerWrapper().handle],
);
```

---

## 📃 License

MIT License — free for commercial and personal use.

---

## 🤝 Contributing

Pull requests, issues, and feature suggestions are welcome. Let's make backend dev in Dart delightful!
