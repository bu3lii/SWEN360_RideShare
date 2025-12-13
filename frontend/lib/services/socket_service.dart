import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';
import 'api_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final ApiService _apiService = ApiService();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('Socket already connected');
      return;
    }

    try {
      final token = await _apiService.token;
      if (token == null) {
        debugPrint('No token available for socket connection');
        return;
      }

      _socket = IO.io(
        ApiConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .setQuery({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(5)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('Socket connected');
        _isConnected = true;
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected');
        _isConnected = false;
      });

      _socket!.onConnectError((error) {
        debugPrint('Socket connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        debugPrint('Socket error: $error');
      });
    } catch (e) {
      debugPrint('Error connecting socket: $e');
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void joinConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('join:conversation', conversationId);
      debugPrint('Joined conversation: $conversationId');
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave:conversation', conversationId);
      debugPrint('Left conversation: $conversationId');
    }
  }

  void onNewMessage(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('message:new', (data) {
        debugPrint('New message received: $data');
        callback(data);
      });
    }
  }

  void offNewMessage() {
    if (_socket != null) {
      _socket!.off('message:new');
    }
  }

  void onTyping(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('user:typing', (data) {
        callback(data);
      });
    }
  }

  void onStoppedTyping(Function(Map<String, dynamic>) callback) {
    if (_socket != null) {
      _socket!.on('user:stopped_typing', (data) {
        callback(data);
      });
    }
  }

  void emitTypingStart(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing:start', conversationId);
    }
  }

  void emitTypingStop(String conversationId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('typing:stop', conversationId);
    }
  }
}

