import 'package:flutter/material.dart';
import 'package:project/screens/welcomepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/screens/signup.dart';
import 'package:project/screens/login.dart';
import 'package:project/screens/home.dart';
import 'package:project/service/SocketService.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final socket = SocketService();
  await socket.connect("10.54.212.157", 8080);
  
  runApp(const MC20(
    startScreen: WelcomePage(),
  ));
}

class MC20 extends StatelessWidget {
  final Widget startScreen;
  const MC20({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MC20',
      theme: lightTheme,
      home: startScreen,
    );
  }
}
