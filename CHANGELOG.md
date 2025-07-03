## 2.3.0
- 🆕 Multipart Form Data Support
  Added full support for parsing multipart/form-data requests, including:
  - 📎 File uploads: parse and extract file metadata (name, size, raw bytes)
  - 📝 Text fields: seamlessly handle combined form inputs and files
  - 💾 Deferred file saving via `getFile()`, storing files on-demand to a temp directory

## 2.2.2
- ✅ Improved request headers and content type handling
- 🐛 Fixed issues related to incorrect or missing Content-Type headers in certain requests

## 2.2.1
- 🐞 Minor bug fixes

## 2.2.0
- 🔄 Refactored middleware and wrapper registration to accept function references directly instead of requiring class instances
- 🧩 `useBefore`, `useAfter`, `wrap`, and `exceptionHandler` now accept plain functions (e.g., `(request) async => Response`) to simplify usage
- 🚀 Encourages a functional programming approach and reduces boilerplate when registering middleware or exception handlers

## 2.1.4
- 🛡️ Added type safety toggle (`enableTypeSafety`) to the `Validator` class for safer and more predictable validation
- ⚠️ Introduced abstract `SiriusException` class to allow custom HTTP/WebSocket exception handling
- 🔧 Updated `start()` method to accept user-defined `exceptionHandler` for centralized error management

## 2.1.3
- Optimized the `Request` class for more efficient and safer data access
- Added `getJsonBody` getter with fallback for null safety
- Improved internal null handling for request parsing

## 2.1.2
- Added `Response.sendJson()` for simplified JSON responses
- Fixed minor bugs and error handling issues

## 2.1.1
- Minor bug fixes related to WebSocket functionality

## 2.1.0
- ✨ **Added** event-based WebSocket communication for structured real-time messaging.  
- 🧹 **Removed** `WebSocketRequest` and replaced with a unified `Request` class for WebSocket handling.  
- 🔌 **Added** WebSocket integration into connection middleware flow.  
- 🧠 **Added** `SocketConnection` class to manage WebSocket events, raw messages, middleware, and connection lifecycle:  
  - 📥 Event registration: `onEvent`, `onceEvent`  
  - 🧾 Raw message handling: `sendData`, `onData`  
  - 🛡️ Middleware validation  
  - 🔁 Connection lifecycle hooks: `disconnect`, `error`  


## 2.0.4
- Web socket error handling
- Improved performance 

## 2.0.3
- Minor error and bug fixes

## 2.0.2
- Improved WebSocket connection handling for better scalability and performance.
- Enhanced error handling and message validation for WebSocket interactions.

## 2.0.1
- 🐞 Minor bug fixes and internal improvements
- 🔧 Improved stability and error handling in route registration and middleware execution

## 2.0.0
### 🚀 Major Release – Sirius Framework 2.0

> This version introduces powerful middleware architecture changes and improved flexibility, with some **breaking changes**.

### ✨ Features & Enhancements

- 🔄 **Introduced wrapper middleware support**  
  Wrappers allow chaining logic (e.g. logging, timing, authentication) _around_ the entire request lifecycle using:
  ```dart
  sirius.wrap(LoggerWrapper());

## 1.0.20
- Minor bug fixes

## 1.0.19
- Validation rules for each elements `ValidationRules().forEachElement()` in list validation
- Minor bug fixes

## 1.0.18
- ✨ Added support for overriding headers in responses using `overrideHeaders` callback
- 🧼 Minor internal code cleanup to enhance maintainability

## 1.0.17
- Improved support for sending custom headers in HTTP responses via the `Response` class
- Internal code cleanup for better maintainability and readability

## 1.0.16
- Minor bug fixes and stability improvements

## 1.0.15
- Some bug fixes

## 1.0.14
- Refactored validation rules to use named parameters instead of positional ones for improved readability and flexibility
- Improved exception messages for better clarity and developer understanding

## 1.0.13
- Bug fixes

## 1.0.12
- Passing and receiving data through middleware
- Minor optimization in handler

## 1.0.11
- Added some more validation rules
- Bug fixes and minor code cleanups

## 1.0.10
- Added support for nested child validation in the `Validator` class 🎯  
  → Use `child` inside `ValidationRules` to validate nested maps  
  → Error messages now support dot notation for nested fields (e.g. `address.street`)
- Improved internal `Validator` logic for better error composition and modularity
- Bug fixes and minor code cleanups

## 1.0.9
- Improved and extended documentation across all core components 📚
- Added example usage to class and method documentation
- Cleaner API reference comments for better IDE support

## 1.0.8
- More controls on headers

## 1.0.7
- More controls in request validation

## 1.0.6
- Bug fixes

## 1.0.5
- Optimized middleware handling

## 1.0.4
- Simplified sending responses

## 1.0.3
- WebSocket support via `app.webSocket(path, handler)` 🎉
- Improved route conflict handling

## 1.0.2
- Small bug fixes version

## 1.0.1
- Small bug fixes version

## 1.0.0
- Initial version
