import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sirius_backend/src/helpers/create_randoms.dart';
import 'package:sirius_backend/src/helpers/helpers.dart';
import 'package:sirius_backend/src/helpers/logging.dart';

/// Signature for WebSocket event callbacks.
///
/// The [data] parameter contains the decoded payload sent by the client.
typedef WebSocketFunction = void Function(Object? data);

/// Signature for middleware functions used to intercept incoming events.
///
/// Return `true` to allow the event to continue.
/// Return `false` to block it.
typedef SocketMiddlewareFunction = FutureOr<bool> Function(
    String event, Object? data);

/// ---------------------------------------------------------------------------
/// WsConnection
/// ---------------------------------------------------------------------------
///
/// A high‑level wrapper around Dart's native [WebSocket] that provides
/// **event‑based communication**, similar to Socket.IO but lightweight
/// and dependency‑free.
///
/// It adds:
/// - Named event listeners
/// - One‑time listeners
/// - Middleware system
/// - Raw message inspection
/// - Structured JSON messaging
/// - Lifecycle hooks (disconnect + error)
///
/// ---------------------------------------------------------------------------
/// 📦 Message Format
/// ---------------------------------------------------------------------------
/// All structured messages must follow this JSON format:
///
/// ```json
/// {
///   "event": "event_name",
///   "data": any
/// }
/// ```
///
/// If a message does not match this structure, it will be ignored.
///
/// ---------------------------------------------------------------------------
/// 🚀 Basic Example
/// ---------------------------------------------------------------------------
/// ```dart
/// final socket = WsConnection(webSocket);
///
/// socket.onEvent("chat", (data) {
///   print("Chat message: $data");
/// });
///
/// socket.sendEvent("welcome", {"message": "Hello client!"});
/// ```
///
/// ---------------------------------------------------------------------------
/// 🛡 Middleware Example
/// ---------------------------------------------------------------------------
/// ```dart
/// socket.use((event, data) {
///   if (event == "admin" && data["token"] != "secret") {
///     return false; // block event
///   }
///   return true;
/// });
/// ```
///
/// ---------------------------------------------------------------------------
/// ⏱ onceEvent Example
/// ---------------------------------------------------------------------------
/// ```dart
/// socket.onceEvent(
///   "pong",
///   (data) => print("Received once: $data"),
///   timeout: Duration(seconds: 5),
///   onTimeout: () => print("Timeout waiting for pong")
/// );
/// ```
///
/// ---------------------------------------------------------------------------
/// 🔌 Disconnect Example
/// ---------------------------------------------------------------------------
/// ```dart
/// socket.onDisconnect(() {
///   print("Client disconnected: ${socket.getId}");
/// });
/// ```
///
/// ---------------------------------------------------------------------------
/// ⚠ Error Handling Example
/// ---------------------------------------------------------------------------
/// ```dart
/// socket.onError((error, stack) {
///   print("Socket error: $error");
/// });
/// ```
/// ---------------------------------------------------------------------------
class WsConnection {
  final WebSocket _webSocket;

  /// Registered event listeners mapped by event name.
  final Map<String, List<WebSocketFunction>> _listeners = {};

  /// Middleware chain executed before dispatching events.
  final List<SocketMiddlewareFunction> _middlewares = [];

  /// Unique ID for this connection instance.
  final String _id;

  /// Optional disconnect handler.
  void Function()? _onDisconnectHandler;

  /// Optional error handler.
  void Function(Object error, StackTrace stackTrace)? _onErrorHandler;

  /// Optional raw data listener.
  void Function(String rawMessage)? _onRawData;

  /// Creates a new [WsConnection] wrapping an existing [WebSocket].
  ///
  /// Automatically attaches listeners for:
  /// - incoming messages
  /// - disconnection
  /// - errors
  WsConnection(this._webSocket) : _id = createUuid() {
    _webSocket.listen(
      _onMessage,
      onDone: _onDone,
      onError: _onError,
    );
  }

  /// Unique identifier for this socket connection.
  ///
  /// This remains constant until the connection closes.
  String get getId => _id;

  // -------------------------------------------------------------------------
  // Internal Handlers
  // -------------------------------------------------------------------------

  /// Processes incoming raw WebSocket messages.
  ///
  /// Steps:
  /// 1. Emits raw data listener (if registered)
  /// 2. Validates JSON structure
  /// 3. Runs middleware chain
  /// 4. Dispatches event to listeners
  Future<void> _onMessage(dynamic data) async {
    try {
      if (_onRawData != null) _onRawData!(data);

      final message = isValidJsonData(data);
      if (message == null) return;

      final event = message["event"];
      final payload = message["data"];

      if (event == null || event is! String) {
        logWarning("[Socket] Invalid event base json structure");
        return;
      }

      for (final middleware in _middlewares) {
        final result = await middleware(event, payload);
        if (!result) return;
      }

      _listeners[event]?.forEach((cb) => cb(payload));
    } catch (e, _) {
      logError("[Socket Error] Invalid message format: $e");
    }
  }

  /// Called automatically when socket closes.
  void _onDone() {
    _listeners.clear();
    _middlewares.clear();

    if (_onDisconnectHandler != null) {
      _onDisconnectHandler?.call();
    } else {
      logWarning("[Socket] Disconnected");
    }
  }

  /// Called automatically when a socket error occurs.
  void _onError(Object error, StackTrace stackTrace) {
    if (_onErrorHandler != null) {
      _onErrorHandler!(error, stackTrace);
    } else {
      logError('[Socket Error] $error');
    }
  }

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Listen to raw incoming data before JSON parsing.
  ///
  /// Useful for:
  /// - debugging
  /// - logging
  /// - inspecting malformed packets
  void onData(void Function(String data) callback) {
    _onRawData = callback;
  }

  /// Registers a callback fired when the client disconnects.
  void onDisconnect(void Function() callback) {
    _onDisconnectHandler = callback;
  }

  /// Registers a handler for socket‑level errors.
  void onError(void Function(Object error, StackTrace stackTrace) callback) {
    _onErrorHandler = callback;
  }

  /// Subscribes to a named event.
  ///
  /// Multiple listeners can be registered for the same event.
  ///
  /// Example:
  /// ```dart
  /// socket.onEvent("message", (data) {
  ///   print(data);
  /// });
  /// ```
  void onEvent(String event, WebSocketFunction callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  /// Removes all listeners associated with [event].
  void offEvent(String event) {
    _listeners.remove(event);
  }

  /// Registers a listener that runs only once.
  ///
  /// After execution, the listener is automatically removed.
  ///
  /// Optional:
  /// - [timeout] → auto‑remove if event never fires
  /// - [onTimeout] → callback when timeout triggers
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
        onTimeout?.call();
      });
    }
  }

  /// Sends a structured event to the client.
  ///
  /// Automatically encodes into JSON format.
  ///
  /// Example:
  /// ```dart
  /// socket.sendEvent("notification", {"title": "New order"});
  /// ```
  void sendEvent(String event, Object? data) {
    final message = jsonEncode({"event": event, "data": data});
    _webSocket.add(message);
  }

  /// Sends raw text data directly to the socket.
  ///
  /// No JSON encoding or validation is performed.
  void sendData(String data) {
    _webSocket.add(data);
  }

  /// Adds middleware to the processing chain.
  ///
  /// Middleware runs **before** event listeners.
  /// If any middleware returns `false`, the event is cancelled.
  void use(SocketMiddlewareFunction middleware) {
    _middlewares.add(middleware);
  }

  /// Direct access to underlying WebSocket instance.
  ///
  /// Use this only if low‑level control is required.
  WebSocket get rawWebSocket => _webSocket;

  /// Closes the socket connection gracefully.
  ///
  /// Defaults to normal closure status.
  Future<void> close({
    int code = WebSocketStatus.normalClosure,
    String? reason,
  }) async {
    await _webSocket.close(code, reason);
  }
}
