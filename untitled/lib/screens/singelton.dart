import 'dart:convert';
import 'dart:io';
import 'dart:async';

class singelton {
  static final singelton _instance = singelton._internal();
  Socket? _socket;

  // کنترل جریان پاسخ‌ها
  final StreamController<Map<String, dynamic>> _controller = StreamController.broadcast();

  factory singelton() {
    return _instance;
  }

  singelton._internal();

  bool get isConnected => _socket != null;

  Future<void> connect(String host, int port) async {
    if (_socket != null) return; // فقط یه بار وصل شه
    _socket = await Socket.connect(host, port);
    print("📡 Connected to $host:$port");

    _socket!.cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((msg) {
      // پیام‌ها ممکنه چند خط باشن
      final messages = msg.split("end");
      for (var m in messages) {
        if (m.trim().isEmpty) continue;
        try {
          final jsonData = json.decode(m.trim());
          _controller.add(jsonData);
        } catch (e) {
          print("❌ JSON parse error: $e");
        }
      }
    }, onError: (err) {
      print("❌ Socket error: $err");
    }, onDone: () {
      print("📴 Socket closed");
      _socket = null;
    });
  }

  void send(Map<String, dynamic> data) {
    if (_socket == null) {
      throw Exception("❌ Socket not connected");
    }
    final jsonString = json.encode(data) + "\n";
    _socket!.write(jsonString);
  }

  void listen(void Function(Map<String, dynamic>) onData) {
    _controller.stream.listen(onData);
  }

  Future<Map<String, dynamic>> sendAndReceive(Map<String, dynamic> data, {Duration timeout = const Duration(seconds: 10)}) async {
    final completer = Completer<Map<String, dynamic>>();
    late StreamSubscription sub;
    sub = _controller.stream.listen((jsonData) {
      if (!completer.isCompleted) {
        completer.complete(jsonData);
      }
    });

    send(data);

    try {
      final result = await completer.future.timeout(timeout, onTimeout: () {
        throw Exception("Socket timeout");
      });
      await sub.cancel();
      return result;
    } catch (e) {
      await sub.cancel();
      rethrow;
    }
  }

  void close() {
    _socket?.destroy();
    _socket = null;
  }
}
