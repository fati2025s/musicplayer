import 'package:flutter/material.dart';
import 'package:project/screens/signup.dart';
import 'theme/theme.dart';

void main() {
  runApp(const MC20());
}

class MC20 extends StatelessWidget {
  const MC20({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MC20',
      theme: appTheme,
      home: const Signup(),
    );
  }
}
