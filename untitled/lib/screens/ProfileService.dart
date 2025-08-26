import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:untitled/screens/singelton.dart';
import '../service/SocketService.dart';

class ProfileService {
  final singelton socketService;

  ProfileService(this.socketService);

  Future<String?> uploadProfileImage(File file) async {
    final base64File = base64Encode(await file.readAsBytes());

    final response = await socketService.sendAndReceive({
      "type": "uploadProfileImage",
      "payload": {
        "fileName": p.basename(file.path),
        "base64Data": base64File,
      }
    });

    if (response["status"] == "success") {
      return response["path"];
    }
    return null;
  }

  Future<bool> addProfileImage(String path) async {
    final response = await socketService.sendAndReceive({
      "type": "addProfileImage",
      "payload": {"path": path},
    });

    return response["status"] == "success";
  }

  Future<bool> setCurrentProfileImage(int index) async {
    final response = await socketService.sendAndReceive({
      "type": "setCurrentProfileImage",
      "payload": {"index": index},
    });

    return response["status"] == "success";
  }

  Future<bool> removeProfileImage(int index) async {
    final response = await socketService.sendAndReceive({
      "type": "removeProfileImage",
      "payload": {"index": index},
    });

    return response["status"] == "success";
  }

  Future<Map<String, dynamic>?> getProfileImages() async {
    final response =
    await socketService.sendAndReceive({"type": "getProfileImages"});

    if (response["status"] == "success") {
      return {
        "images": List<String>.from(response["images"]),
        "currentIndex": response["currentIndex"] ?? 0,
      };
    }
    return null;
  }
}
