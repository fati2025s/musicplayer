import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/screens/singelton.dart';
import '../models/user.dart';
import 'Signup.dart';
import 'dart:convert';
import 'HomeScreen.dart';
import 'package:local_auth/local_auth.dart';

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

  final LocalAuthentication auth = LocalAuthentication();
  bool _supportsBiometric = false;

  @override
  void initState() {
    super.initState();
    //_checkLoginStatus();
    _checkBiometricSupport();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      setState(() {
        _supportsBiometric = canCheck && isSupported;
      });
    } catch (e) {
      setState(() {
        _supportsBiometric = false;
      });
    }
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final username = _controllerUsername.text;
    final password = _controllerPassword.text;
    final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (username.isEmpty || !passwordRegex.hasMatch(password)) {
      setState(() => message = "Username or password is invalid");
      return;
    }

    final requestBody = {
      "type": "login",
      "payload": {
        "id": Random().nextInt(100000),
        "username": username,
        "password": password,
        "profilePicturePath": [],
        "songs": [],
        "playlists": [],
        "likedSongs": [],
      }
    };

    try {
      final socketService = singelton();
      await socketService.connect("10.208.175.99", 8080);

      socketService.listen((responseJson) {
        setState(() {
          message = responseJson["message"] ?? "Unknown response";
        });
        if (responseJson["status"] == "success") {
          final user = User.fromJson(responseJson["data"]["user"]);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => HomeScreen(currentu: user)),
            );
          });
        }
      });

      socketService.send(requestBody);
    } catch (e) {

      setState(() => message = "Connection failed: $e");
    }
  }


  /*Future<void> _authenticate() async {
    try {
      bool didAuthenticate = await auth.authenticate(
        localizedReason: "لطفا اثر انگشت خود را تایید کنید",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("loginStatus", true);
        await prefs.setString("userName", "BiometricUser");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        setState(() => message = "اثر انگشت تایید نشد");
      }
    } catch (e) {
      setState(() => message = "خطا در ورود با اثر انگشت: $e");
    }
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("loginStatus") ?? false) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // بک‌گراند بره پشت اپ‌بار هم
      backgroundColor: Colors.transparent,
      //backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body:Stack(
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
          Form(
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

                  // Username
                  TextFormField(
                    controller: _controllerUsername,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: "Username",
                      prefixIcon: const Icon(Icons.person_outline,color: Colors.black,),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onEditingComplete: () => _focusNodePassword.requestFocus(),
                    validator: (value) =>
                    value == null || value.isEmpty ? "Enter username" : null,
                  ),
                  const SizedBox(height: 10),

                  // Password
                  TextFormField(
                    controller: _controllerPassword,
                    focusNode: _focusNodePassword,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline,color: Colors.black,),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? "Enter password" : null,
                  ),
                  const SizedBox(height: 40),
                  // Login button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Color(0xFF8A0000),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _login,
                    child: const Text("Login"),
                  ),
                  /*const SizedBox(height: 10),

                  // Fingerprint button (only if supported)
                  if (_supportsBiometric)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      icon: const Icon(Icons.fingerprint),
                      label: const Text("Login with Fingerprint"),
                      onPressed: _authenticate,
                    ),

                  const SizedBox(height: 20),
    */
                  // Signup link
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
                  const SizedBox(height: 10),

                  // Message
                  Text(message, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
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
