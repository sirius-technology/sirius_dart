# Sirius ⚡ — A Lightweight Dart Backend Framework

Sirius is a lightweight, expressive, and fast HTTP & WebSocket backend framework built entirely with Dart. Designed for simplicity, performance, and developer productivity, it provides powerful routing, middleware, and request validation features for building modern backend APIs.

---

## 🚀 Features

- Simple and chainable routing (GET, POST, PUT, PATCH, DELETE)
- Grouped route management
- Middleware support (before & after)
- WebSocket integration
- Powerful and extensible request validation
- Nested object and list validation support
- Easy-to-use request & response handling
- Built with `dart:io` for performance

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  sirius_backend: ^1.0.18
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
sirius.get('/users', getUsersHandler);
sirius.post('/users', createUserHandler);
sirius.put('/users/:id', updateUserHandler);
sirius.delete('/users/:id', deleteUserHandler);
```

### Grouped Routes

```dart
sirius.group('/api', (group) {
  group.get('/status', (req) async => Response.send({'ok': true}));
});
```

---

## 🔐 Middleware

### Global Middleware

```dart
sirius.useBefore(AuthMiddleware());
sirius.useAfter(LoggerMiddleware());
```

### Route Middleware

```dart
sirius.get('/secure',
  (req) async => Response.send('Authorized'),
  useBefore: [AuthMiddleware()]
);
```

### Middleware Example

```dart
class AuthMiddleware extends Middleware {
  @override
  Future<Response> handle(Request request) async {
    final token = request.headerValue('authorization');
    if (token == 'valid-token') {
      request.passData = {'userId': 123};
      return Response.next();
    }
    return Response.send({'error': 'Unauthorized'}, status: 401);
  }
}
```

---

## 📦 Request Object

```dart
final id = request.pathVariable('id');
final name = request.jsonValue('name');
final headers = request.headers;
final method = request.method;
final userData = request.receiveData; // from middleware
```

---

## ✅ Validation

### Basic Usage

```dart
final validator = Validator(request.getAllFields(), {
  'name': ValidationRules(required: required(message: "Name is required")),
  'age': ValidationRules(minNumber: minNumber(18)),
});

if (!validator.validate()) {
  return Response.send(validator.getAllErrors, status: 400);
}
```

### Nested Map Validation

```dart
'address': ValidationRules(
  dataType: dataType(DataTypes.MAP),
  childMap: {
    'street': ValidationRules(required: required()),
    'zip': ValidationRules(minLength: minLength(5)),
  },
)
```

### Nested List Validation

```dart
'items': ValidationRules(
  dataType: dataType(DataTypes.LIST),
  childList: [
    ValidationRules(required: required(message: "Item name is required")),
  ],
)
```

---

## 🔄 WebSocket Support

```dart
sirius.webSocket('/chat', (socket) {
  socket.listen((msg) {
    socket.add('Echo: $msg');
  });
});
```

---

## 📤 Response

```dart
return Response.send({"message": "Success"});
return Response.send({"error": "Unauthorized"}, status: 401);
return Response.next(); // used inside middleware
```

---

## 📄 Request Validation Utilities

You can define reusable validation rules like:

```dart
ValidationRules(
  required: required(),
  dataType: dataType(DataTypes.STRING),
  minLength: minLength(3),
  maxLength: maxLength(50),
  inList: inList(["admin", "user"]),
)
```

---

## 📌 Development Notes

- Sirius is built using Dart's native `dart:io` server.
- Intended for REST APIs, internal tools, and WebSocket-based microservices.
- Fully typed, with customizable validation and extensible middleware patterns.

---

## 📃 License

MIT License. Feel free to use and modify.

---
