import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sirius_backend/src/helpers/create_randoms.dart';
import 'package:sirius_backend/src/helpers/logging.dart';

/// Callback function type for handling socket events.
typedef WebSocketFunction = void Function(dynamic data);

/// Middleware function type for intercepting and validating events.
typedef SocketMiddlewareFunction = bool Function(String event, dynamic data);

/// A wrapper for managing WebSocket connections using event-based communication,
/// similar to Socket.IO.
///
/// Provides functionality to register event listeners, one-time event handlers,
/// middleware for validation, raw message listeners, and connection lifecycle handlers.
///
/// Example:
/// ```dart
/// socket.onEvent("message", (data) {
///   print("Received message: $data");
/// });
///
/// socket.sendEvent("greet", {"hello": "world"});
/// ```
class SocketConnection {
  final WebSocket _webSocket;
  final Map<String, WebSocketFunction> _listeners = {};
  final List<SocketMiddlewareFunction> _middlewares = [];
  final String _id;

  void Function()? _onDisconnectHandler;
  Function? _onErrorHandler;
  void Function(String rawMessage)? _onRawData;

  SocketConnection(this._webSocket) : _id = createUuid() {
    _webSocket.listen(
      _onMessage,
      onDone: _onDone,
      onError: _onError,
    );
  }

  /// A unique identifier for this WebSocket connection.
  ///
  /// It remains constant for the lifetime of the connection.
  String get getId => _id;

  /// Internal handler for incoming socket messages.
  void _onMessage(dynamic data) {
    try {
      if (_onRawData != null) _onRawData!(data);

      final message = jsonDecode(data);
      final event = message["event"];
      final payload = message["data"];

      for (SocketMiddlewareFunction middleware in _middlewares) {
        final bool allowed = middleware(event, payload);
        if (!allowed) return;
      }

      _listeners[event]?.call(payload);
    } catch (e, _) {
      logError("[Socket Error] Invalid message format: $e");
    }
  }

  /// Internal handler for socket disconnection.
  void _onDone() {
    _listeners.clear();
    _middlewares.clear();

    if (_onDisconnectHandler != null) {
      _onDisconnectHandler?.call();
    } else {
      print("[Socket] Disconnected");
    }
  }

  /// Internal handler for socket errors.
  void _onError(error, stackTrace) {
    if (_onErrorHandler != null) {
      _onErrorHandler!(error, stackTrace);
    } else {
      logError('[Socket Error] $error');
    }
  }

  /// Registers a raw message listener for unprocessed incoming messages.
  ///
  /// Useful for debugging or low-level inspection.
  void onData(void Function(String data) callback) {
    _onRawData = callback;
  }

  /// Registers a disconnect handler.
  ///
  /// Called when the client disconnects.
  void onDisconnect(void Function() callback) {
    _onDisconnectHandler = callback;
  }

  /// Registers an error handler.
  ///
  /// Called when a socket-level error occurs.
  void onError(Function callback) {
    _onErrorHandler = callback;
  }

  /// Registers a listener for a specific event.
  ///
  /// Example:
  /// ```dart
  /// socket.onEvent("chat", (data) => print("Chat: $data"));
  /// ```
  void onEvent(String event, WebSocketFunction callback) {
    _listeners[event] = callback;
  }

  /// Removes the listener for the specified [event].
  void offEvent(String event) {
    _listeners.remove(event);
  }

  /// Registers a one-time event listener for a given [event].
  ///
  /// The listener is removed automatically after the first call.
  /// Optionally, provide a [timeout] after which the listener is removed
  /// if not called, and an [onTimeout] callback.
  ///
  /// Example:
  /// ```dart
  /// socket.onceEvent("pong", (data) => print("Pong received"), timeout: Duration(seconds: 5));
  /// ```
  void onceEvent(
    String event,
    WebSocketFunction callback, {
    Duration? timeout,
    void Function()? onTimeout,
  }) {
    Timer? timer;

    void wrapper(data) {
      callback(data);
      offEvent(event);
      timer?.cancel();
    }

    onEvent(event, wrapper);

    if (timeout != null) {
      timer = Timer(timeout, () {
        offEvent(event);
        if (onTimeout != null) {
          onTimeout();
        }
      });
    }
  }

  /// Sends an event with associated [data] to the connected client.
  ///
  /// The message is automatically wrapped in a JSON object.
  ///
  /// Example:
  /// ```dart
  /// socket.sendEvent("notification", {"title": "New order"});
  /// ```
  void sendEvent(String event, dynamic data) {
    final message = jsonEncode({"event": event, "data": data});
    _webSocket.add(message);
  }

  /// Sends raw string [data] to the connected client without any JSON wrapping.
  ///
  /// Example:
  /// ```dart
  /// socket.sendData('{"custom": "message"}');
  /// ```
  void sendData(String data) {
    _webSocket.add(data);
  }

  /// Adds a middleware function to intercept and validate events.
  ///
  /// If any middleware returns `false`, the event is blocked.
  ///
  /// Example:
  /// ```dart
  /// socket.use((event, data) {
  ///   if (event == "admin-only" && !isAdmin(data)) return false;
  ///   return true;
  /// });
  /// ```
  void use(SocketMiddlewareFunction middleware) {
    _middlewares.add(middleware);
  }

  /// Provides direct access to the raw [WebSocket] object.
  WebSocket get rawWebSocket => _webSocket;

  /// Closes the WebSocket connection.
  ///
  /// You may provide a custom [code] and [reason] for closing.
  Future<void> close({
    int code = WebSocketStatus.normalClosure,
    String? reason,
  }) async {
    await _webSocket.close(code, reason);
  }
}
