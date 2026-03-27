import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sirius_backend/src/constants/constant_methods.dart';
import 'package:sirius_backend/src/helpers/create_randoms.dart';
import 'package:sirius_backend/src/helpers/logging.dart';

typedef WsEventHandler = void Function(Object? data);
typedef WsMiddleware = FutureOr<bool> Function(String event, Object? data);
typedef WsErrorHandler = void Function(Object error, StackTrace stack);

class _WsRoomEngine {
  final Map<String, Set<WsConnection>> _rooms = {};
  final Map<String, Set<String>> _socketRooms = {};

  void join(WsConnection socket, String room) {
    _rooms.putIfAbsent(room, () => {}).add(socket);
    _socketRooms.putIfAbsent(socket._id, () => {}).add(room);
  }

  void leave(WsConnection socket, String room) {
    _rooms[room]?.remove(socket);
    _socketRooms[socket._id]?.remove(room);

    if (_rooms[room]?.isEmpty ?? false) {
      _rooms.remove(room);
    }
  }

  void leaveAll(WsConnection socket) {
    final rooms = _socketRooms[socket._id];
    if (rooms == null) return;

    for (final r in rooms) {
      final set = _rooms[r];
      set?.remove(socket);
      if (set?.isEmpty ?? false) {
        _rooms.remove(r);
      }
    }

    _socketRooms.remove(socket._id);
  }

  Set<String> roomsOf(WsConnection socket) => _socketRooms[socket._id] ?? {};

  void emit(String room, String event, Object? data, {WsConnection? except}) {
    final sockets = _rooms[room];
    if (sockets == null) return;

    final encoded = jsonEncode({"event": event, "data": data});

    for (final s in List.from(sockets)) {
      // 🔥 CORRECTED (safe iteration)
      if (except != null && s == except) continue;
      s._sendRaw(encoded);
    }
  }
}

final _rooms = _WsRoomEngine();

/// =======================================================================
/// WsRoomEmitter
/// =======================================================================
///
/// Used for broadcasting events to a specific room.
///
/// Example:
///
/// ws.join('room1');
///
/// ws.to('room1').emit('chat', {
///   'message': 'Hello everyone'
/// });
///
/// To exclude sender:
///
/// ws.to('room1').emitExceptMe('chat', {
///   'message': 'Hello except me'
/// });
class WsRoomEmitter {
  final String room;
  final WsConnection sender;

  WsRoomEmitter(this.room, this.sender);

  /// Broadcasts an event to all sockets in the room.
  ///
  /// Example:
  ///
  /// ws.to('room1').emit('chat', {
  ///   'message': 'Hello everyone'
  /// });
  ///
  /// The sender is INCLUDED in broadcast.
  void emit(String event, Object? data) {
    _rooms.emit(room, event, data);
  }

  /// Broadcasts an event to all sockets in the room
  /// except the sender.
  ///
  /// Example:
  ///
  /// ws.to('room1').emitExceptMe('chat', {
  ///   'message': 'Hello others'
  /// });
  ///
  /// The sender will NOT receive this event.
  void emitExceptMe(String event, Object? data) {
    _rooms.emit(room, event, data, except: sender);
  }
}

/// =======================================================================
/// WsConnection
/// =======================================================================
///
/// Represents a single WebSocket client connection.
///
/// This class provides:
///
/// • Event-based messaging (`on`, `emit`)
/// • Room-based broadcasting (`join`, `to`)
/// • Middleware support (`use`)
/// • One-time listeners (`once`)
/// • Rate limiting (100 messages/sec)
/// • Payload size guard (100KB)
/// • Raw message handling mode
/// • Error handling hooks
/// • Automatic cleanup on disconnect
///
/// -----------------------------------------------------------------------
/// BASIC EXAMPLE
/// -----------------------------------------------------------------------
///
/// app.webSocket('/ws', (Request req) async {
///   final ws = await req.upgradeToWebSocket();
///
///   ws.on('hello', (data) {
///     ws.emit('reply', {'message': 'Hello client'});
///   });
///
///   ws.onDisconnect(() {
///     print('Client disconnected: ${ws.getId}');
///   });
/// });
///
/// -----------------------------------------------------------------------
/// MESSAGE FORMAT (Default Mode)
/// -----------------------------------------------------------------------
///
/// Incoming messages must follow:
///
/// {
///   "event": "event_name",
///   "data": { ... }
/// }
///
/// -----------------------------------------------------------------------
/// RAW MODE
/// -----------------------------------------------------------------------
///
/// If you register:
///
///   ws.onRaw((raw) {
///     print(raw);
///   });
///
/// Then non-JSON messages are allowed.
///
/// -----------------------------------------------------------------------
/// RATE LIMITING
/// -----------------------------------------------------------------------
///
/// Each connection is limited to:
///
///   100 messages per second
///
/// If exceeded, connection closes with:
///
///   1008 → Policy violation
///
/// -----------------------------------------------------------------------
/// PAYLOAD SIZE LIMIT
/// -----------------------------------------------------------------------
///
/// Max payload size:
///
///   100 KB
///
/// If exceeded:
///
///   1009 → Message too big
///
/// -----------------------------------------------------------------------
/// CLOSE CODES
/// -----------------------------------------------------------------------
///
/// 1000 → Normal close
/// 1003 → Unsupported data
/// 1008 → Rate limit exceeded
/// 1009 → Message too large
class WsConnection {
  final WebSocket _socket;

  late final String _id;

  final Map<String, List<WsEventHandler>> _listeners = {};
  final List<WsMiddleware> _middlewares = [];

  void Function()? _onDisconnect;
  WsErrorHandler? _onSocketError;
  WsErrorHandler? _onDataError;

  void Function(String raw)? _onRaw;

  bool _closed = false;

  int _messageCount = 0;
  DateTime _lastReset = DateTime.now();

  WsConnection(this._socket) {
    _id = createUuid();

    _socket.pingInterval = const Duration(seconds: 30);

    _socket.listen(
      _handleMessage,
      onDone: _handleClose,
      onError: _handleErr,
    );
  }

  /// Unique identifier of this WebSocket connection.
  ///
  /// This ID is auto-generated when the connection is created.
  ///
  /// Useful for:
  /// • Tracking users
  /// • Broadcasting sender identity
  /// • Debug logging
  ///
  /// Example:
  ///
  /// print(ws.getId);
  String get getId => _id;

  /// Registers an event listener.
  ///
  /// Example:
  ///
  /// ws.on('chat', (data) {
  ///   print(data);
  /// });
  ///
  /// Multiple listeners can be registered for the same event.
  void on(String event, WsEventHandler cb) {
    _listeners.putIfAbsent(event, () => []).add(cb);
  }

  /// Removes an event listener.
  ///
  /// If [handler] is provided:
  ///   → Only that specific listener is removed.
  ///
  /// If [handler] is null:
  ///   → All listeners for the event are removed.
  ///
  /// Example:
  ///
  /// ws.off('chat'); // remove all chat listeners
  ///
  /// ws.off('chat', myHandler); // remove specific handler
  void off(String event, [WsEventHandler? handler]) {
    if (handler == null) {
      _listeners.remove(event);
    } else {
      _listeners[event]?.remove(handler);
    }
  }

  /// Registers a one-time event listener.
  ///
  /// The handler is automatically removed after first execution.
  ///
  /// Optional [timeout] removes the listener if event
  /// does not fire within the duration.
  ///
  /// Example:
  ///
  /// ws.once('payment_success', (data) {
  ///   print('Payment confirmed');
  /// }, timeout: Duration(seconds: 30));
  void once(String event, WsEventHandler cb, {Duration? timeout}) {
    Timer? timer;

    void wrapper(data) {
      cb(data);
      off(event, wrapper);
      timer?.cancel();
    }

    on(event, wrapper);

    if (timeout != null) {
      timer = Timer(timeout, () {
        off(event, wrapper);
      });
    }
  }

  /// Adds middleware for event interception.
  ///
  /// Middleware runs before event handlers.
  ///
  /// Return:
  ///   true  → Continue execution
  ///   false → Block event
  ///
  /// Example:
  ///
  /// ws.use((event, data) async {
  ///   if (event == 'admin_only' && !isAdmin(ws)) {
  ///     return false;
  ///   }
  ///   return true;
  /// });
  void use(WsMiddleware mw) => _middlewares.add(mw);

  /// Joins this socket to a room.
  ///
  /// Example:
  ///
  /// ws.join('chat_room');
  void join(String room) => _rooms.join(this, room);

  /// Removes this connection from a specific room.
  ///
  /// Example:
  ///
  /// ws.leave('chat_room');
  ///
  /// If the room becomes empty, it is automatically deleted.
  void leave(String room) => _rooms.leave(this, room);

  /// Removes this connection from all joined rooms.
  ///
  /// Example:
  ///
  /// ws.leaveAll();
  ///
  /// Automatically called when the connection disconnects.
  void leaveAll() => _rooms.leaveAll(this);

  /// Returns all rooms joined by this connection.
  ///
  /// Example:
  ///
  /// final joinedRooms = ws.rooms;
  /// print(joinedRooms);
  ///
  /// Returns an empty Set if no rooms joined.
  Set<String> get rooms => _rooms.roomsOf(this);

  /// Returns a room emitter for broadcasting.
  ///
  /// Example:
  ///
  /// ws.to('chat_room').emit('message', {'text': 'Hello'});
  WsRoomEmitter to(String room) => WsRoomEmitter(room, this);

  /// Sends an event to this socket.
  ///
  /// Example:
  ///
  /// ws.emit('chat', {'message': 'Hello'});
  void emit(String event, Object? data) {
    _sendRaw(jsonEncode({"event": event, "data": data}));
  }

  /// Sends raw string data directly to the client.
  ///
  /// Unlike [emit], this does NOT wrap the message
  /// in the Sirius event JSON format.
  ///
  /// Example:
  ///
  /// ws.send('plain text message');
  ///
  /// ⚠ Use this only if you control the client protocol.
  /// For standard Sirius messaging, prefer [emit].
  void send(String raw) => _sendRaw(raw);

  void _sendRaw(String data) {
    if (_closed) return;

    try {
      _socket.add(data);
    } catch (err, st) {
      // 🔥 CORRECTED (correct error channel)
      _onSocketError?.call(err, st);
      if (_onSocketError == null) {
        logException(err, st);
      }
    }
  }

  /// Registers a disconnect handler.
  ///
  /// Called when:
  /// • Client closes connection
  /// • Server closes connection
  /// • Network drops
  ///
  /// Example:
  ///
  /// ws.onDisconnect(() {
  ///   print('Client ${ws.getId} disconnected');
  /// });
  ///
  /// Only one disconnect handler can be registered.
  /// Registering again overrides the previous one.
  void onDisconnect(void Function() fn) => _onDisconnect = fn;

  /// Registers a low-level socket error handler.
  ///
  /// Triggered when:
  /// • Underlying WebSocket throws
  /// • Send failures occur
  void onSocketError(WsErrorHandler fn) => _onSocketError = fn;

  /// Registers an error handler for event callbacks.
  ///
  /// Triggered when an event listener throws an exception.
  void onDataError(WsErrorHandler fn) => _onDataError = fn;

  /// Enables raw message handling mode.
  ///
  /// When enabled:
  /// • Non-JSON messages are allowed
  /// • Invalid JSON will NOT be rejected
  ///
  /// Example:
  ///
  /// ws.onRaw((raw) {
  ///   print('Received raw: $raw');
  /// });
  ///
  /// If not registered, Sirius expects messages in:
  ///
  /// {
  ///   "event": "event_name",
  ///   "data": ...
  /// }
  ///
  /// ⚠ Intended for custom protocols or streaming.
  void onRaw(void Function(String raw) fn) => _onRaw = fn;

  /// Closes this WebSocket connection.
  ///
  /// Default close code:
  ///   1000 → Normal closure
  ///
  /// Example:
  ///
  /// await ws.close();
  Future<void> close([int code = 1000]) async {
    if (_closed) return;
    _closed = true;
    await _socket.close(code);
  }

  Future<void> _handleMessage(dynamic raw) async {
    try {
      if (raw is! String) {
        logWarning(
            "WS [$_id]: Binary frame received but Sirius expects text-based JSON messages. Connection closed (1003).");
        await close(1003);
        return;
      }

      _onRaw?.call(raw);

      if (raw.length > 100000) {
        logWarning(
            "WS [$_id]: Payload exceeded 100KB limit. Connection closed (1009 - message too big).");
        await close(1009);
        return;
      }

      final now = DateTime.now();
      if (now.difference(_lastReset).inSeconds >= 1) {
        _messageCount = 0;
        _lastReset = now;
      }

      _messageCount++;
      if (_messageCount > 100) {
        logWarning(
            "WS [$_id]: Rate limit exceeded (more than 100 messages/sec). Connection closed (1008 - policy violation).");
        await close(1008); // policy violation
        return;
      }

      Map<String, dynamic>? decoded;

      try {
        final temp = jsonDecode(raw);

        if (temp is Map<String, dynamic>) {
          decoded = temp;
        } else {
          // Valid JSON but not Map
          if (_onRaw == null) {
            logWarning(
                "WS [$_id]: Invalid JSON received. Expected: $protocolFormat. Message ignored.");
            // await close(1003);
            return;
          }
        }
      } catch (_) {
        // Invalid JSON syntax
        if (_onRaw == null) {
          logWarning(
              "WS [$_id]: Invalid message structure. Expected: $protocolFormat. Message ignored.");
          // await close(1003);
          return;
        } else {
          return; // raw mode allowed
        }
      }

      if (decoded == null) return;

      final event = decoded["event"];
      final data = decoded["data"];

      if (event is! String) {
        if (_onRaw == null) {
          logWarning(
              "WS [$_id]: 'event' field must be a String. Message ignored.");
          // await close(1003);
        }
        return;
      }

      for (final mw in _middlewares) {
        final ok = await mw(event, data);
        if (!ok) return;
      }

      final list = _listeners[event];
      if (list == null) return;

      for (final cb in List.from(list)) {
        try {
          cb(data);
        } catch (err, st) {
          _onDataError?.call(err, st);
          if (_onDataError == null) {
            logException(err, st);
          }
        }
      }
    } catch (err, st) {
      _onDataError?.call(err, st);
      if (_onDataError == null) {
        logException(err, st);
      }
    }
  }

  void _handleClose() {
    if (_closed) return;
    _closed = true;

    _rooms.leaveAll(this);
    _listeners.clear();
    _middlewares.clear();

    _onDisconnect?.call();
  }

  void _handleErr(Object e, StackTrace st) {
    _onSocketError?.call(e, st);
    if (_onSocketError == null) {
      logException(e, st);
    }
  }
}
