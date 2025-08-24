import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:untitled/screens/HomeScreen.dart';
import 'package:untitled/screens/Login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:untitled/screens/singelton.dart';

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
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _controllerUsername.text;
    final email = _controllerEmail.text;
    final password = _controllerPassword.text;

    final requestBody = {
      "type": "register",
      "payload": {
        "id": Random().nextInt(100000),
        "username": username,
        "email": email,
        "password": password,
        "profilePicturePath": [],
        "songs": [],
        "playlists": [],
        "likedSongs": [],
        "likedArtists": [],
      }
    };

    try {
      final socketService = singelton();
      await socketService.connect("172.20.98.97", 8080);

      socketService.listen((responseJson) {
        setState(() {
          message = responseJson["message"] ?? "Unknown response";
        });

        if (responseJson["status"] == "success") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      });

      socketService.send(requestBody);
    } catch (e) {
      setState(() {
        message = "Connection failed: $e";
      });
    }
  }



  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true, // بک‌گراند بره پشت اپ‌بار هم
      backgroundColor: Colors.transparent, // پس‌زمینه شفاف
      //backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.red,
                  Colors.white,
                ],
                stops: [0.2, 1.0],
              ),
            ),
          ),
          SafeArea(
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
                        prefixIcon: const Icon(Icons.person_outline,color: Colors.black,),
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
                        prefixIcon: const Icon(Icons.email_outlined,color: Colors.black,),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40)),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter email.";
                        }
                        final emailRegex = RegExp(r'^[A-Za-z0-9]+@[A-Za-z0-9]+\.[A-Za-z]{2,}$');
                        if (!emailRegex.hasMatch(value)) {
                          return "Invalid email format.";
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
                        prefixIcon: const Icon(Icons.lock,color: Colors.black,),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          icon: _obscurePassword
                              ? const Icon(Icons.visibility_outlined,color: Colors.black,)
                              : const Icon(Icons.visibility_off_outlined,color: Colors.black,),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40)),
                      ),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password.";
                        }
                        final passwordRegex =
                        RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
                        if (!passwordRegex.hasMatch(value)) {
                          return "Invalid.";
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
                        prefixIcon: const Icon(Icons.lock,color: Colors.black,),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          icon: _obscurePassword
                              ? const Icon(Icons.visibility_outlined,color: Colors.black,)
                              : const Icon(Icons.visibility_off_outlined,color: Colors.black,),
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
                            backgroundColor: Color(0xFF8A0000),
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
                              child: const Text("Login",
                                style: TextStyle(color: Colors.red),),
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
      ],
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