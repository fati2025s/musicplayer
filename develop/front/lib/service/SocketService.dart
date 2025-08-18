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
      print("✅ Connected to server: $host:$port");

      _socket.listen((data) {
        final str = utf8.decode(data).trim();
        print("📥 Raw from server: $str");

        // 🔹 پیام‌ها با \n جدا میشن (نه end)
        final parts = str.split("\n");

        for (var part in parts) {
          if (part.trim().isEmpty) continue;
          try {
            final jsonResp = jsonDecode(part);
            if (jsonResp['requestId'] != null &&
                _pendingRequests.containsKey(jsonResp['requestId'])) {
              _pendingRequests[jsonResp['requestId']]!.complete(jsonResp);
              _pendingRequests.remove(jsonResp['requestId']);
            } else {
              print("📥 Untracked response: $jsonResp");
            }
          } catch (e) {
            print("⚠️ Error parsing response: $e | raw: $part");
          }
        }
      }, onDone: () {
        _connected = false;
        print("📴 Disconnected from server");
      }, onError: (err) {
        _connected = false;
        print("❌ Socket error: $err");
      });
    } catch (e) {
      print("❌ Error connecting to server: $e");
    }
  }

  bool get isConnected => _connected;

  Future<void> send(Map<String, dynamic> request) async {
    if (!_connected) {
      print("⚠️ Socket not connected");
      return;
    }
    final reqStr = jsonEncode(request) + "\n"; // 🔹 سرور همون \n رو انتظار داره
    _socket.write(reqStr);
    await _socket.flush();
  }

  Future<Map<String, dynamic>> sendAndWait(
      Map<String, dynamic> request) async {
    if (!_connected) {
      throw Exception("❌ Socket not connected");
    }

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    request['requestId'] = requestId;

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    final reqStr = jsonEncode(request) + "\n";
    _socket.write(reqStr);
    await _socket.flush();

    return completer.future.timeout(
      const Duration(seconds: 7),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException("⏱ No response from server for $requestId");
      },
    );
  }

  // 🔑 Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final request = {
      "type": "login",
      "payload": {
        "username": username,
        "password": password,
      }
    };
    return await sendAndWait(request);
  }

  // 📝 Register
  Future<Map<String, dynamic>> register(
      String username, String password, String email) async {
    final request = {
      "type": "register",
      "payload": {
        "username": username,
        "password": password,
        "email": email,
      }
    };
    return await sendAndWait(request);
  }

  // 🎶 Playlist APIs
  Future<Map<String, dynamic>> addPlaylist(String name) async {
    final request = {
      "type": "addPlaylist",
      "payload": {"name": name}
    };
    return await sendAndWait(request);
  }

  Future<Map<String, dynamic>> deletePlaylist(int playlistId) async {
    final request = {
      "type": "deletePlaylist",
      "payload": {"id": playlistId}
    };
    return await sendAndWait(request);
  }

  Future<Map<String, dynamic>> getPlaylists() async {
    final request = {
      "type": "getplaylists",
      "payload": {}
    };
    return await sendAndWait(request);
  }

  Future<Map<String, dynamic>> getPlaylist(int playlistId) async {
    final request = {
      "type": "getplaylist",
      "payload": {"id": playlistId}
    };
    return await sendAndWait(request);
  }

  void close() {
    _socket.close();
    _pendingRequests.clear();
  }
}
