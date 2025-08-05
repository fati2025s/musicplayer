import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:aslasl/screens/HomeScreen.dart';
import 'package:aslasl/screens/Login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerConFirmPassword =
  TextEditingController();
  String message = '';

  bool _obscurePassword = true;
  Map<String, String> _accounts = {};

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("accounts");
    if (raw != null) {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _accounts = decoded.map((k, v) => MapEntry(k, v.toString()));
    }
  }

  Future<void> _saveAccount(String username, String password) async {
    _accounts[username] = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("accounts", json.encode(_accounts));
  }

  void _register() async {
    if (!(_formKey.currentState?.validate() ?? false)){
      return;
    }
    final username = _controllerUsername.text;
    final email = _controllerEmail.text;
    final password = _controllerPassword.text;
    final confirmPassword = _controllerConFirmPassword.text;
    //final studentNumber = "123456789";

    if (password.length < 8 ||
        !email.endsWith("@gmail.com") ||
        username.isEmpty ||
        password != confirmPassword) {
      setState(() {
        message = "Some input is invalid!";
      });
      return;
    }

    final requestBody = {
      "type": "register",
      "payload": {
        "username": username,
        "email": email,
        "password": password,
      }
    };

    final jsonString = json.encode(requestBody) + '\n';

    try {
      var socket = await Socket.connect("172.25.138.99", 8080);
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    }  catch (e) {
      setState(() {
        message = "Connection failed: $e";
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              children: [
                const SizedBox(height: 100),
                Text("Register",
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 10),
                Text("Create your account",
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 35),
                TextFormField(
                  controller: _controllerUsername,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: "Username",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter username.";
                    } else if (_accounts.containsKey(value)) {
                      return "Username is already registered.";
                    }
                    return null;
                  },
                  onEditingComplete: () => _focusNodeEmail.requestFocus(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerEmail,
                  focusNode: _focusNodeEmail,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter email.";
                    } else if (!(value.contains('@') && value.contains('.'))) {
                      return "Invalid email";
                    }
                    return null;
                  },
                  onEditingComplete: () => _focusNodePassword.requestFocus(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerPassword,
                  obscureText: _obscurePassword,
                  focusNode: _focusNodePassword,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: _obscurePassword
                          ? const Icon(Icons.visibility_outlined)
                          : const Icon(Icons.visibility_off_outlined),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter password.";
                    } else if (value.length < 8) {
                      return "Password must be at least 8 characters.";
                    }
                    return null;
                  },
                  onEditingComplete: () =>
                      _focusNodeConfirmPassword.requestFocus(),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerConFirmPassword,
                  obscureText: _obscurePassword,
                  focusNode: _focusNodeConfirmPassword,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: _obscurePassword
                          ? const Icon(Icons.visibility_outlined)
                          : const Icon(Icons.visibility_off_outlined),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40)),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm password.";
                    } else if (value != _controllerPassword.text) {
                      return "Passwords do not match.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 50),
                if (message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),

                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _register,
                      child: const Text("Register"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account?"),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()),
                            );
                          },
                          child: const Text("Login"),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    _controllerConFirmPassword.dispose();
    super.dispose();
  }
}
