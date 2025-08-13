import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:project/screens/home.dart';
import 'package:project/screens/login.dart';
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
  final TextEditingController _controllerConFirmPassword = TextEditingController();

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
      setState(() {
        _accounts = decoded.map((k, v) => MapEntry(k, v.toString()));
      });
    }
  }

  Future<void> _saveAccount(String username, String password) async {
    _accounts[username] = password;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("accounts", json.encode(_accounts));
  }

  void _showToast(String msg, {Color color = Colors.red}) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  Future<void> _register() async {
    final username = _controllerUsername.text.trim();
    final email = _controllerEmail.text.trim();
    final password = _controllerPassword.text;
    final confirmPassword = _controllerConFirmPassword.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showToast("Please fill all fields.");
      return;
    }

    if (_accounts.containsKey(username)) {
      _showToast("Username is already registered.");
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showToast("Invalid email format.");
      return;
    }

    if (password != confirmPassword) {
      _showToast("Passwords do not match.");
      return;
    }

    final passwordRegex = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      _showToast(
          "Password must be at least 8 characters, include 1 uppercase letter and 1 number."
      );
      return;
    }

    await _saveAccount(username, password);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("loginStatus", true);
    await prefs.setString("userName", username);

    _showToast("Registered successfully!", color: Colors.green);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              Text("Register", style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 10),
              Text("Create your account", style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 35),
              TextFormField(
                controller: _controllerUsername,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: _obscurePassword
                        ? const Icon(Icons.visibility_outlined)
                        : const Icon(Icons.visibility_off_outlined),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onEditingComplete: () => _focusNodeConfirmPassword.requestFocus(),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerConFirmPassword,
                obscureText: _obscurePassword,
                focusNode: _focusNodeConfirmPassword,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: _obscurePassword
                        ? const Icon(Icons.visibility_outlined)
                        : const Icon(Icons.visibility_off_outlined),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 50),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                            MaterialPageRoute(builder: (context) => const Login()),
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
