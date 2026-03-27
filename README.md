# Sirius ⚡ — A Lightweight Dart Backend Framework

Sirius is a lightweight, expressive, and fast HTTP & WebSocket backend framework built entirely with Dart.  
It features powerful routing, composable wrapper middlewares, validation, and lifecycle hooks.

---

## 🚀 Features

- ⚡ Simple, expressive routing (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`)
- 🧱 Wrapper middleware via `.wrap()` for lifecycle-level logic (e.g. logging, timing)
- 🔀 Grouped routes for modular structure
- 🔐 Validation with nested object and list support
- 🌐 WebSocket routing support
- 💡 Built on top of `dart:io` for raw performance

---

## 📦 Installation

```yaml
dependencies:
  sirius_backend: ^2.4.3
````

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

## 🌀 Wrapper Middleware (NEW in 2.0)

Wrappers allow full control over the request lifecycle for tasks like logging, auth, timing, etc.

```dart
class TimerWrapper extends Wrapper {
  @override
  FutureOr<Response?> handle(Request request, FutureOr<Response?> Function() nextHandler) async {
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
sirius.get('/dashboard', controller.dashboardHandler, wrappers: [TimerWrapper().handle]);
```

---

## 🧾 Request Object

```dart
final id = request.pathVariable('id');
final name = request.jsonValue('name');
final headers = request.headers;
final method = request.method;
final userData = request.getContextData; // Passed via middleware
```

---

## 🧭 Request Lifecycle Flow

```
Incoming Request
  └── Global Wrapper (Entry)
      └── Route Wrapper (Entry)
          └── Route Handler
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
4️⃣ Route Handler (your main logic)
    ↓
5️⃣ Route Wrapper (Exit)
    ↓
6️⃣ Global Wrapper (Exit)
    ↓
7️⃣ 🟢 Response Sent
```

---

## ✅ Validation

### Basic Validation

```dart
final validator = Validator(request, {
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
sirius.webSocket('/chat', (request) async {
  final socketConn = await request.upgradeToWebSocket();
  final connId = socketConn.getId;
  print("Client connected: $connId");

  // Respond to a custom event
  socketConn.on("ping", (data) {
    print("Received ping: $data");
    socketConn.emit("pong", {
      "message": "Pong received!",
      "echo": data,
    });
  });

  // Listen to raw messages (not event-based)
  socketConn.onRaw((msg) {
    print("Raw message: $msg");
    socketConn.send("Echo: $msg");
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
sirius.get(
  '/secure-data',
  secureDataHandler,
  wrappers: [
    TimerWrapper().handle,
    AuthWrapper().handle,
  ],
);
```

---

## 📃 License

MIT License — free for commercial and personal use.

---

## 🤝 Contributing

Pull requests, issues, and feature suggestions are welcome.
Let’s make backend development in Dart delightful!
