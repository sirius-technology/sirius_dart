## 2.3.5
- 🔁 Removed unintended loop execution of middlewares to ensure wrappers run only once per request
- 🧹 Minor internal cleanup and optimization

## 2.3.4
- 🌐 Added built-in `corsHandler` middleware to simplify CORS handling across projects
- 🛠️ Developers can now easily enable CORS using `.wrap(corsHandler())` with customizable options

## 2.3.3
- ⚙️ Improved compliance with HTTP `HEAD` method by ensuring responses include headers only and no body
- 🔍 Enhanced header handling logic to support custom and client-provided headers more cleanly
- 🧪 Added better testing support for `HEAD`, `OPTIONS`, and other non-GET methods

## 2.3.2
- 🐞 Fixed minor errors and bugs

## 2.3.1
- 🐞 Minor bug fixes
- 🤝 Developer experience improvements for better usability and clarity

## 2.3.0
### 🆕 Multipart Form Data Support
- 📎 **File Uploads**
  - Parse and extract file metadata like name, size, and raw bytes from multipart/form-data requests.
- 📝 **Text Fields**
  - Seamlessly handle both file and text inputs in a single multipart request.
- 💾 **Deferred File Saving**
  - Files are not saved automatically.
  - Use `request.getFile('fieldName')` to manually save and retrieve the file from a temporary directory.

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
