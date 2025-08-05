import 'package:aslasl/screens/Login.dart';
import 'package:flutter/material.dart';
import 'package:aslasl/screens/HomeScreen.dart';
import 'package:aslasl/screens/Signup.dart';
import 'package:aslasl/screens/Login.dart';
import 'theme/theme.dart';

void main() {
  runApp(const NovakApp());
}

class NovakApp extends StatelessWidget {
  const NovakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novak',
      theme: appTheme,
      home: Login(),
    );
  }
}
