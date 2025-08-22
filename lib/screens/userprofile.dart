import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerEmail = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  bool _isEditing = false;
  bool _obscurePassword = true;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _controllerUsername.text = prefs.getString('username') ?? 'amirabbas amadeh';
    _controllerEmail.text = prefs.getString('email') ?? 'amirabbasamadeh1@email.com';
    _controllerPassword.text = prefs.getString('password') ?? '12345678';
    String? imagePath = prefs.getString('profileImage');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
    }
    setState(() {});
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _controllerUsername.text);
    await prefs.setString('email', _controllerEmail.text);
    await prefs.setString('password', _controllerPassword.text);
    if (_profileImage != null) {
      await prefs.setString('profileImage', _profileImage!.path);
    }
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _profileImage = File(picked.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode_outlined),
            onPressed: () {
            },
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                if (_formKey.currentState?.validate() ?? false) {
                  _saveUserData();
                }
              } else {
                setState(() {
                  _isEditing = true;
                });
              }
            },
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
          child: Column(
            children: [
              GestureDetector(
                onTap: _isEditing ? _pickImage : null,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!)
                      : const AssetImage('assets/default_avatar.png')
                  as ImageProvider,
                  child: _isEditing
                      ? const Align(
                    alignment: Alignment.bottomRight,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 20),
                    ),
                  )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _controllerUsername,
                enabled: _isEditing,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _controllerEmail,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter email';
                  } else if (!(value.contains('@') && value.contains('.'))) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _controllerPassword,
                enabled: _isEditing,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter password' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controllerUsername.dispose();
    _controllerEmail.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}
