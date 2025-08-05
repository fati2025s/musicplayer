import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Signup.dart';
import '../screens/HomeScreen.dart';
import 'dart:convert';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodePassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  String message = "";

  bool _obscurePassword = true;

  Map<String, String> _registeredAccounts = {};

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadRegisteredAccounts();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final username = _controllerUsername.text;
    final password = _controllerPassword.text;
    if(username.isEmpty || password.length < 8){
      setState(() {
        message = "Some input is invalid";
      });
      return;
    }

    final requestBody = {
      "type": "login",
      "payload": {
        "username": username,
        "password": password,
      }
    };

    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("10.218.184.99", 8080);
      StringBuffer responseText = StringBuffer();
      final completer = Completer<String>();

      socket.write(jsonString);
      await socket.flush();

      socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (data) {
          print("📥 دریافت شد: $data");
          responseText.write(data);

          if (data.contains("end")) {
            socket.close();
            completer.complete(responseText.toString());
          }
        },
        onError: (error) {
          print("❌ خطا: $error");
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        onDone: () {
          print("📴 اتصال بسته شد");
          if (!completer.isCompleted) {
            completer.complete(responseText.toString());
          }
        },
        cancelOnError: true,
      );

      final result = await completer.future;
      print("result:$result");
      final Map<String, dynamic> responseJson =
      json.decode(result.replaceAll("end", ""));

      setState(() {
        message = responseJson["message"] ?? "Unknown response";
      });

      if (responseJson["success"] == "success") {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("loginStatus", true);
        await prefs.setString("userName", username);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
      else{
        setState(() {
          message = responseJson["message"] ?? "Login faild.";
        });
      }
    }  catch (e) {
      setState(() {
        message = "Connection failed: $e";
      });
    }

  }

  Future<void> _checkLoginStatus() async {

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool("loginStatus") ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HomeScreen()));
    }
  }

  Future<void> _loadRegisteredAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString("accounts");
    if (jsonString != null) {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      setState(() {
        _registeredAccounts =
            decoded.map((key, value) => MapEntry(key, value.toString()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 150),
              Text("Welcome back",
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text("Login to your account",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 60),
              TextFormField(
                controller: _controllerUsername,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onEditingComplete: () => _focusNodePassword.requestFocus(),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please enter username.";
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerPassword,
                focusNode: _focusNodePassword,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: _obscurePassword
                        ? const Icon(Icons.visibility_outlined)
                        : const Icon(Icons.visibility_off_outlined),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  final username = _controllerUsername.text;
                  if (value == null || value.isEmpty)
                    return "Please enter password.";
                  return null;
                },
              ),
              const SizedBox(height: 60),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _login,
                    child: const Text("Login"),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          _formKey.currentState?.reset();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Signup()),
                          );
                        },
                        child: const Text("Signup"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodePassword.dispose();
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}
