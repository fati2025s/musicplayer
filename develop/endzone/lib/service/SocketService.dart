// ===================== lib/service/SocketService.dart =====================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  Socket? _socket;
  bool _connected = false;

  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final StreamController<Map<String, dynamic>> _streamController =
  StreamController.broadcast();

  Future<void> connect(String host, int port) async {
    if (_connected && _socket != null) return;
    try {
      _socket = await Socket.connect(host, port);
      _connected = true;
      print('✅ Connected to server: $host:$port');

      String _buffer = ""; // 🔥 بافر محلی برای جمع‌کردن داده‌ها

      _socket!.listen((data) {
        final str = utf8.decode(data);
        _buffer += str; // تکه داده رو اضافه می‌کنیم به بافر

        // پردازش تا وقتی که خط کامل (با \n) داشته باشیم
        while (_buffer.contains('\n')) {
          final idx = _buffer.indexOf('\n');
          final line = _buffer.substring(0, idx).trim();
          _buffer = _buffer.substring(idx + 1);

          if (line.isEmpty) continue;
          try {
            final jsonResp = jsonDecode(line) as Map<String, dynamic>;
            final reqId = jsonResp['requestId'];
            if (reqId != null && _pendingRequests.containsKey(reqId)) {
              _pendingRequests[reqId]!.complete(jsonResp);
              _pendingRequests.remove(reqId);
            } else {
              _streamController.add(jsonResp);
            }
          } catch (e) {
            print('❌ Error parsing response: $e | raw: $line');
          }
        }
      }, onDone: () {
        _connected = false;
        print('🔌 Disconnected from server');
      }, onError: (err) {
        _connected = false;
        print('⚠️ Socket error: $err');
      });
    } catch (e) {
      print('❌ Error connecting: $e');
    }
  }


  bool get isConnected => _connected;
  Stream<Map<String, dynamic>> get eventsStream => _streamController.stream;

  Future<Map<String, dynamic>> sendAndWait(Map<String, dynamic> request) async {
    if (!_connected || _socket == null) throw Exception('Socket not connected');

    final requestId = DateTime.now().millisecondsSinceEpoch.toString();
    request['requestId'] = requestId;

    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[requestId] = completer;

    _socket!.write(jsonEncode(request) + '\n');
    await _socket!.flush();

    final resp = await completer.future.timeout(
      const Duration(seconds: 100),
      onTimeout: () {
        _pendingRequests.remove(requestId);
        throw TimeoutException('Timeout for $requestId');
      },
    );

    return resp;
  }

  Future<Map<String, dynamic>> _sendWithAuth(
      String type, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    if (username == null || password == null) {
      throw Exception('User not authenticated');
    }

    final fullPayload = {
      'type': type,
      'payload': {'username': username, 'password': password, ...payload}
    };

    return await sendAndWait(fullPayload);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final resp = await sendAndWait({
      'type': 'login',
      'payload': {'username': username, 'password': password}
    });

    if (resp['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);
      await prefs.setString('password', password);
    }
    return resp;
  }

  Future<Map<String, dynamic>> register(
      String username, String password, String email) async {
    return await sendAndWait({
      'type': 'register',
      'payload': {'username': username, 'password': password, 'email': email}
    });
  }

  Future<Map<String, dynamic>> logout() async {
    final resp = await _sendWithAuth('logout', {});
    if (resp['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      close();
    }
    return resp;
  }

  Future<Map<String, dynamic>> addPlaylist(String name) async =>
      await _sendWithAuth('addPlaylist', {'name': name});

  Future<Map<String, dynamic>> deletePlaylist(int playlistId) async =>
      await _sendWithAuth('deletePlaylist', {'playlistId': playlistId});

  Future<Map<String, dynamic>> renamePlaylist(
      int playlistId, String newName) async =>
      await _sendWithAuth(
          'renamePlaylist', {'playlistId': playlistId, 'newName': newName});

  Future<Map<String, dynamic>> listPlaylists() async =>
      await _sendWithAuth('listPlaylists', {});

  Future<Map<String, dynamic>> sharePlaylist(
      int playlistId, String targetUsername) async =>
      await _sendWithAuth('sharePlaylist',
          {'playlistId': playlistId, 'targetUsername': targetUsername});

  Future<Map<String, dynamic>> uploadSongFile(
      String filePath, Map<String, String> meta) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);

    return await _sendWithAuth('uploadSongFile', {
      'fileName': file.uri.pathSegments.last,
      'base64Data': base64Data,
      'meta': meta
    });
  }


  Future<File> downloadSong(int songId, String savePath) async {
    final file = File(savePath);
    final sink = file.openWrite();

    final completer = Completer<File>();

    // 🎯 به‌جای sendAndWait از send مستقیم استفاده می‌کنیم
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    final password = prefs.getString('password');
    if (username == null || password == null) {
      throw Exception('User not authenticated');
    }

    final request = {
      'type': 'downloadSong',
      'payload': {'username': username, 'password': password, 'songId': songId},
      'requestId': DateTime.now().millisecondsSinceEpoch.toString(),
    };

    _socket!.write(jsonEncode(request) + '\n');
    await _socket!.flush();

    // 🎧 گوش دادن به پیام‌ها
    StreamSubscription<Map<String, dynamic>>? subscription;
    subscription = eventsStream.listen((resp) {
      final msg = resp['message'];
      if (msg == 'download_chunk') {
        final b64 = resp['data']['base64'] as String;
        sink.add(base64Decode(b64));
      } else if (msg == 'download_complete') {
        sink.close();
        subscription?.cancel();
        print('✅ Download complete: $savePath');
        completer.complete(file);
      }
    });

    return completer.future;
  }



  Future<Map<String, dynamic>> deleteSong(int songId) async =>
      await _sendWithAuth('deleteSong', {'songId': songId});

  Future<Map<String, dynamic>> listSongs() async =>
      await _sendWithAuth('listSongs', {});

  Future<Map<String, dynamic>> toggleLikeSong(int songId) async {
    return await _sendWithAuth('toggleLikeSong', {
      'songId': songId,
    });
  }


  Future<Map<String, dynamic>> listTopLikedSongs() async =>
      await _sendWithAuth('listTopLikedSongs', {});

  Future<Map<String, dynamic>> listUsers() async =>
      await _sendWithAuth('listUsers', {});

  Future<Map<String, dynamic>> changePassword(String oldPw, String newPw) async =>
      await _sendWithAuth('changePassword', {
        'oldPassword': oldPw,
        'newPassword': newPw,
      });

  // آهنگ‌های لایک شده (بک باید متادیتا نگه‌داره)
  Future<Map<String, dynamic>> listLikedSongs() async =>
      await _sendWithAuth('listLikedSongs', {});

  // لایک کردن همراه متادیتا
  Future<Map<String, dynamic>> likeSongWithMeta(
      int songId, Map<String, dynamic> meta) async {
    return await _sendWithAuth('likeSong', {
      'songId': songId,
      'meta': meta,
    });
  }


  Future<Map<String, dynamic>> listRecentlyPlayed({int limit = 20}) async =>
      await _sendWithAuth('listRecentlyPlayed', {'limit': limit});



  Future<Map<String, dynamic>> deleteAccount() async {
    final resp = await _sendWithAuth('deleteAccount', {});
    if (resp['status'] == 'success') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      close(); // قطع اتصال سوکت
    }
    return resp;
  }

  void close() {
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    _connected = false;
    _pendingRequests.clear();
    print('Socket closed');
  }
}