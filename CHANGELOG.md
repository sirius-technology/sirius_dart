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
