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
