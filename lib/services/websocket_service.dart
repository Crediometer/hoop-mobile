// lib/services/base_websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hoop/constants/strings.dart';
import 'package:hoop/dtos/podos/tokens/token_manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

typedef SocketEventHandler = void Function(dynamic data);

class BaseWebSocketService with ChangeNotifier {

  final String namespace;
  final Duration reconnectInterval;
  final int maxReconnectAttempts;
  final TokenManager tokenManager = TokenManager.instance;

  io.Socket? _socket;
  Timer? _heartbeatTimer;
  Timer? _connectionTimeoutTimer;
  int _reconnectAttempts = 0;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isDisposed = false;
  String? _userId;
  String? _connectionError;

  // Connection event callbacks
  VoidCallback? onConnectedCallback;
  VoidCallback? onConnectingCallback;
  Function(String)? onDisconnectedCallback;
  Function(dynamic)? onErrorCallback;
  Function(int)? onReconnectAttemptCallback;

  BaseWebSocketService({

    required this.namespace,
    this.reconnectInterval = const Duration(seconds: 5),
    this.maxReconnectAttempts = 10,
    this.onConnectedCallback,
    this.onConnectingCallback,
    this.onDisconnectedCallback,
    this.onErrorCallback,
    this.onReconnectAttemptCallback,
  });

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get userId => _userId;
  String? get connectionError => _connectionError;
  io.Socket? get socket => _socket;

  // Event registration methods
  void onConnected(VoidCallback callback) => onConnectedCallback = callback;
  void onConnecting(VoidCallback callback) => onConnectingCallback = callback;
  void onDisconnected(Function(String) callback) => onDisconnectedCallback = callback;
  void onError(Function(dynamic) callback) => onErrorCallback = callback;
  void onReconnectAttempt(Function(int) callback) => onReconnectAttemptCallback = callback;

  // Token management


  Future<String?> _getUserIdFromToken() async {
    try {
      final token = await tokenManager!.getToken();
      if (token == null) return null;

      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      return payloadMap['userId']?.toString() ?? payloadMap['sub']?.toString();
    } catch (e) {
      debugPrint('❌ Error parsing token: $e');
      return null;
    }
  }

  // Connection management
  Future<void> connect() async {
    if (_isConnecting || _isConnected || _isDisposed) return;

    _isConnecting = true;
    _connectionError = null;
    
    onConnectingCallback?.call();
    notifyListeners();

    try {
      final token = await tokenManager.getToken();
      final userId = await _getUserIdFromToken();

      if (token == null) {
        debugPrint('⚠️ No token or user ID available for socket connection');
        _isConnecting = false;
        _connectionError = 'Authentication required';
        notifyListeners();
        return;
      }

      _userId = userId;

      // Clean up existing socket
      if (_socket != null) {
        _socket!.disconnect();
        _socket!.dispose();
      }

      // Create socket connection
      _socket = io.io(
        '$WS_BASE_URL$namespace',
        io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setTimeout(20000)
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(maxReconnectAttempts)
          .setReconnectionDelay(reconnectInterval.inMilliseconds)
          .setReconnectionDelayMax(30000)
          .build(),
      );

      _setupEventListeners();

      _connectionTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!_isConnected && _isConnecting) {
          debugPrint('⏰ Connection timeout');
          _isConnecting = false;
          _connectionError = 'Connection timeout';
          notifyListeners();
          _socket?.disconnect();
          _scheduleReconnect();
        }
      });

      _socket!.connect();
      
    } catch (e) {
      debugPrint('❌ Error connecting to socket: $e');
      _isConnecting = false;
      _connectionError = e.toString();
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      _connectionTimeoutTimer?.cancel();
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionError = null;
      
      debugPrint('🎉 Connected to $namespace');
      
      _startHeartbeat();
      
      onConnectedCallback?.call();
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      final reason = _socket?.disconnected == true ? 'Disconnected' : 'Connection lost';
      debugPrint('🔌 Disconnected from $namespace: $reason');
      
      _stopHeartbeat();
      
      onDisconnectedCallback?.call(reason);
      notifyListeners();
      
      if (!_isDisposed) {
        _scheduleReconnect();
      }
    });

    _socket!.onConnectError((error) {
      _connectionTimeoutTimer?.cancel();
      _isConnecting = false;
      _connectionError = error.toString();
      debugPrint('❌ Connection error to $namespace: $error');
      
      onErrorCallback?.call(error);
      notifyListeners();
      
      if (!_isDisposed) {
        _scheduleReconnect();
      }
    });

    _socket!.onError((error) {
      _connectionError = error.toString();
      debugPrint('❌ Socket error in $namespace: $error');
      onErrorCallback?.call(error);
    });

    _socket!.onReconnect((_) {
      debugPrint('🔄 Reconnecting to $namespace...');
      _isConnecting = true;
      onConnectingCallback?.call();
      notifyListeners();
    });

    _socket!.onReconnectAttempt((attempt) {
      debugPrint('🔄 Reconnect attempt $attempt for $namespace');
      onReconnectAttemptCallback?.call(attempt);
    });

    _socket!.onReconnectError((error) {
      debugPrint('❌ Reconnect error for $namespace: $error');
      onErrorCallback?.call(error);
    });

    _socket!.onReconnectFailed((_) {
      debugPrint('❌ Reconnect failed for $namespace');
      onErrorCallback?.call('Reconnect failed');
    });

    _socket!.on('error', (data) {
      debugPrint('❌ Server error: $data');
      onErrorCallback?.call(data);
    });

    _socket!.on('unauthorized', (data) {
      debugPrint('❌ Unauthorized: $data');
      _connectionError = 'Unauthorized: $data';
      disconnect();
    });

    _socket!.on('ping', (_) {
      _socket?.emit('pong');
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (_isConnected && _socket?.connected == true) {
        _socket?.emit('heartbeat', {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'userId': _userId,
        });
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_isDisposed || _reconnectAttempts >= maxReconnectAttempts) {
      if (_reconnectAttempts >= maxReconnectAttempts) {
        debugPrint('❌ Max reconnect attempts ($maxReconnectAttempts) reached for $namespace');
        _connectionError = 'Max reconnection attempts reached';
        notifyListeners();
      }
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(
      seconds: min(reconnectInterval.inSeconds * _reconnectAttempts, 60),
    );
    
    debugPrint('🔄 Scheduling reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');
    
    Timer(delay, () {
      if (!_isConnected && !_isConnecting && !_isDisposed) {
        debugPrint('🔄 Attempting to reconnect...');
        connect();
      }
    });
  }

  void disconnect() {
    debugPrint('👋 Disconnecting from $namespace...');
    
    _isDisposed = false;
    
    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = null;
    
    _stopHeartbeat();
    
    if (_socket?.connected == true) {
      _socket?.disconnect();
    }
    
    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    
    notifyListeners();
  }

  void reconnect() {
    if (_isConnecting) return;
    
    _reconnectAttempts = 0;
    connect();
  }

  void emit(String event, [dynamic data]) {
    if (!_isConnected || _socket == null) {
      debugPrint('⚠️ Cannot emit $event: Socket not connected');
      return;
    }
    
    try {
      _socket!.emit(event, data);
    } catch (e) {
      debugPrint('❌ Error emitting event $event: $e');
    }
  }

  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, handler);
  }

  void off(String event) {
    _socket?.off(event);
  }

  void clearError() {
    _connectionError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing BaseWebSocketService for $namespace');
    
    _isDisposed = true;
    
    _connectionTimeoutTimer?.cancel();
    _stopHeartbeat();
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    super.dispose();
  }
}