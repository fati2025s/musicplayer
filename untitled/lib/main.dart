import 'package:flutter/material.dart';
import 'package:untitled/screens/WelcomePage.dart';
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
      home: WelcomePage(),
    );
  }
}