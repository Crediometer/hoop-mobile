// lib/services/websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hoop/dtos/responses/Notifications/notification.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseWebSocketService with ChangeNotifier {
  final String _baseUrl;
  final String _namespace;
  final Duration _reconnectInterval;
  final int _maxReconnectAttempts;

  late io.Socket _socket;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _userId;

  BaseWebSocketService({
    required String baseUrl,
    required String namespace,
    Duration reconnectInterval = const Duration(seconds: 5),
    int maxReconnectAttempts = 10,
  })  : _baseUrl = baseUrl,
        _namespace = namespace,
        _reconnectInterval = reconnectInterval,
        _maxReconnectAttempts = maxReconnectAttempts;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get userId => _userId;

  // Abstract methods for child classes to implement
  void onConnect();
  void onDisconnect(String reason);
  void onError(dynamic error);
  void onNotification(NotificationModel notification);
  void onMessage(ChatMessage message);

  // Token management
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  Future<String?> _getUserIdFromToken() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      // Parse JWT token to get user ID
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(decoded) as Map<String, dynamic>;
      
      return payloadMap['userId'] ?? payloadMap['sub'];
    } catch (e) {
      debugPrint('Error parsing token: $e');
      return null;
    }
  }

  // Connection management
  Future<void> connect() async {
    if (_isConnecting || _isConnected) return;

    _isConnecting = true;
    notifyListeners();

    try {
      final token = await _getToken();
      final userId = await _getUserIdFromToken();

      if (token == null || userId == null) {
        debugPrint('No token or user ID available');
        _isConnecting = false;
        notifyListeners();
        return;
      }

      _userId = userId;

      // Create socket connection
      _socket = io.io(
        '$_baseUrl$_namespace',
        io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          // 20000 (20 seconds)
          .setTimeout(10000)
          .setAuth({'token': token})
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(_reconnectInterval.inMilliseconds)
          .build(),
      );

      // Setup event listeners
      _setupEventListeners();

      // Connect
      _socket.connect();
    } catch (e) {
      debugPrint('Error connecting to socket: $e');
      _isConnecting = false;
      notifyListeners();
      _scheduleReconnect();
    }
  }

  void _setupEventListeners() {
    _socket.onConnect((_) {
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      debugPrint('Connected to $_namespace');
      
      onConnect();
      notifyListeners();
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      final reason = _socket.disconnected ? 'Disconnected' : 'Connection lost';
      debugPrint('Disconnected from $_namespace: $reason');
      
      onDisconnect(reason);
      notifyListeners();
      _scheduleReconnect();
    });

    _socket.onConnectError((error) {
      _isConnecting = false;
      debugPrint('Connection error to $_namespace: $error');
      
      onError(error);
      notifyListeners();
    });

    _socket.onError((error) {
      debugPrint('Socket error in $_namespace: $error');
      onError(error);
    });

    // Common events
    _socket.on('new_notification', (data) {
      try {
        final notification = NotificationModel.fromJson(data);
        onNotification(notification);
      } catch (e) {
        debugPrint('Error parsing notification: $e');
      }
    });

    _socket.on('new_message', (data) {
      try {
        final message = ChatMessage.fromJson(data);
        onMessage(message);
      } catch (e) {
        debugPrint('Error parsing message: $e');
      }
    });
  }

  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnect attempts reached for $_namespace');
      return;
    }

    _reconnectTimer = Timer(_reconnectInterval, () {
      _reconnectAttempts++;
      debugPrint('Attempting to reconnect to $_namespace (attempt $_reconnectAttempts)');
      _reconnectTimer = null;
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    
    if (_socket.connected) {
      _socket.disconnect();
    }
    
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  void emit(String event, [dynamic data]) {
    if (!_isConnected) {
      debugPrint('Cannot emit $event: Socket not connected');
      return;
    }
    _socket.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    _socket.on(event, handler);
  }

  void off(String event) {
    _socket.off(event);
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}