import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SocketService {
  late Socket _socket;
  bool _connected = false;
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  SocketService();

  Future<void> connect(String host, int port) async {
    try {
      _socket = await Socket.connect(host, port);
      _connected = true;
      print("Connected to server");

      _socket.listen((data) {
        final str = String.fromCharCodes(data).trim();

        final parts = str.split("end");
        for (var part in parts) {
          if (part.trim().isEmpty) continue;
          try {
            final jsonResp = jsonDecode(part);
            if (jsonResp['requestId'] != null &&
                _pendingRequests.containsKey(jsonResp['requestId'])) {
              _pendingRequests[jsonResp['requestId']]!.complete(jsonResp);
              _pendingRequests.remove(jsonResp['requestId']);
            }
          } catch (_) {
            print("Non-JSON message: $part");
          }
        }
      }, onDone: () {
        _connected = false;
        print("Disconnected from server");
      });
    } catch (e) {
      print("Error connecting to server: $e");
    }
  }

  bool get isConnected => _connected;

  Future<void> send(Map<String, dynamic> request) async {
    if (!_connected) {
      print("Socket not connected");
      return;
    }
    final reqStr = jsonEncode(request) + "\n";
    _socket.write(reqStr);
    await _socket.flush();
  }

  Future<Map<String, dynamic>> sendAndWait(
      Map<String, dynamic> request) async {
    if (!_connected) {
      throw Exception("Socket not connected");
    }

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    request['requestId'] = requestId;

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    final reqStr = jsonEncode(request) + "\n";
    _socket.write(reqStr);
    await _socket.flush();

    return completer.future
        .timeout(const Duration(seconds: 5), onTimeout: () {
      _pendingRequests.remove(requestId);
      throw TimeoutException("No response from server for $requestId");
    });
  }

  void close() {
    _socket.close();
    _pendingRequests.clear();
  }
}
