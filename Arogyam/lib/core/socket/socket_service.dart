import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io_client;
import '../../app/config/environment.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io_client.Socket? _socket;
  bool _isConnected = false;
  String? _lastToken;

  final _appointmentStatusController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get appointmentStatusStream => _appointmentStatusController.stream;

  final _receptionQueueUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get receptionQueueUpdatedStream => _receptionQueueUpdatedController.stream;

  bool get isConnected => _isConnected;

  /// Returns base host URL for socket server (e.g. http://127.0.0.1:3000)
  String get _socketUrl {
    final apiBase = AppConfig.baseUrl; // e.g. http://127.0.0.1:3000/api
    final uri = Uri.parse(apiBase);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  /// Initializes or reuses the single Socket.io connection with auth token
  void connect({String? token}) {
    if (token != null) {
      _lastToken = token;
    }

    if (_socket != null && _socket!.connected) {
      if (token != null) {
        _socket!.emit('join', {'token': token});
      }
      return;
    }

    try {
      _socket = io_client.io(
        _socketUrl,
        io_client.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(10)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('[SocketService] Connected to $_socketUrl');
        _isConnected = true;
        if (_lastToken != null) {
          _socket!.emit('join', {'token': _lastToken});
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('[SocketService] Disconnected from socket server');
        _isConnected = false;
      });

      _socket!.onConnectError((err) {
        debugPrint('[SocketService] Connect error: $err');
        _isConnected = false;
      });

      _socket!.on('appointment_status', (data) {
        debugPrint('[SocketService] Received appointment_status: $data');
        if (data is Map) {
          _appointmentStatusController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('reception:queue_updated', (data) {
        debugPrint('[DIAGNOSTIC] [SocketService] Received reception:queue_updated event: $data');
        if (data is Map) {
          _receptionQueueUpdatedController.add(Map<String, dynamic>.from(data));
        }
      });

      _socket!.connect();
    } catch (e) {
      debugPrint('[SocketService] Failed to establish socket: $e');
    }
  }

  /// Subscribe directly to an appointment room for targeted updates
  void subscribeToAppointment(String appointmentId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('subscribe_appointment', {'appointmentId': appointmentId});
      _socket!.on('appointment_status:$appointmentId', (data) {
        if (data is Map) {
          _appointmentStatusController.add(Map<String, dynamic>.from(data));
        }
      });
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
