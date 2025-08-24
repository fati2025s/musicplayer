import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TextPage extends StatelessWidget {
  final String? text;
  const TextPage({Key? key, this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("متن آهنگ")),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: text != null && text!.isNotEmpty ?
          SingleChildScrollView(
            child: Text(
              text!,
              style: const TextStyle(fontSize: 18),
            ),
          )
              : const Center(
            child: Text(" بدون متن آهنگ",
              style: TextStyle(fontSize: 18),
            ),
          )
      ),
    );
  }
}