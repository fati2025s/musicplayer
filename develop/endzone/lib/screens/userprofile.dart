import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../service/SocketService.dart';
import 'Login.dart';

class UserProfileScreen extends StatefulWidget {
  final SocketService socketService;

  const UserProfileScreen({
    super.key,
    required this.socketService,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
    _controllerUsername.text = prefs.getString('username') ?? 'Default User';
    _controllerEmail.text = prefs.getString('email') ?? 'user@email.com';
    _controllerPassword.text = prefs.getString('password') ?? '12345678';

    final imagePath = prefs.getString('profileImage');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
    }
    if (mounted) setState(() {});
  }

  Future<void> _saveUserData() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final prefs = await SharedPreferences.getInstance();
    final oldUsername = prefs.getString('username');
    final oldEmail = prefs.getString('email');
    final oldPassword = prefs.getString('password');

    final newUsername = _controllerUsername.text.trim();
    final newEmail = _controllerEmail.text.trim();
    final newPassword = _controllerPassword.text;

    try {
      if (widget.socketService.isConnected) {
        final payload = <String, dynamic>{};
        if (newUsername != oldUsername) payload['newUsername'] = newUsername;
        if (newEmail != oldEmail) payload['newEmail'] = newEmail;
        if (newPassword != oldPassword) payload['newPassword'] = newPassword;

      }
    } catch (e) {
      debugPrint('Error syncing profile to server: $e');
      if (mounted) _showSnack('Network error while syncing', isError: true);
    }

    await prefs.setString('username', newUsername);
    await prefs.setString('email', newEmail);
    await prefs.setString('password', newPassword);
    if (_profileImage != null) {
      await prefs.setString('profileImage', _profileImage!.path);
    }

    if (mounted) {
      setState(() => _isEditing = false);
      _showSnack('Profile updated successfully');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    setState(() => _profileImage = file);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', file.path);
    } catch (_) {}
  }


  Future<void> _logout() async {
    try {
      if (widget.socketService.isConnected) {
        final resp = await widget.socketService.logout();
        print('logout response: $resp');
      } else {
        print('socket not connected, proceeding to clear prefs');
      }
    } catch (e) {
      debugPrint('Error in logout (socket): $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('prefs cleared');

    if (!mounted) return;

    try {
      Navigator.of(context, rootNavigator: true)
          .pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('pushNamed failed, falling back to direct widget push: $e');
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => Login()),
            (route) => false,
      );
    }
  }


  Future<void> _deleteAccount() async {
    try {
      if (widget.socketService.isConnected) {
        final resp = await widget.socketService.deleteAccount();
        if (resp['status'] != 'success') {
          if (mounted) {
            _showSnack(resp['message'] ?? 'Failed to delete account',
                isError: true);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) _showSnack('Network error while deleting account', isError: true);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
    }
  }

  Future<void> _changePasswordDialog() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              decoration: const InputDecoration(labelText: 'Old Password'),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                final resp = await widget.socketService
                    .changePassword(oldController.text, newController.text);
                final success = resp['status'] == 'success';

                if (success) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('password', newController.text);
                  _controllerPassword.text = newController.text;
                }

                if (mounted) {
                  Navigator.pop(ctx);
                  _showSnack(
                      success
                          ? 'Password changed successfully'
                          : 'Failed to change password',
                      isError: !success);
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  _showSnack('Network error', isError: true);
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? theme.colorScheme.error : theme.colorScheme.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('User Profile'),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.red, Colors.white],
                stops: [0.2, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
              child: Form(
                key: _formKey,
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
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                            ),
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _controllerUsername,
                      enabled: _isEditing,
                      decoration: _inputDecoration(
                        label: 'Username',
                        icon: Icons.person_outline,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter username'
                          : null,
                    ),
                    const SizedBox(height: 10),

                    // Email
                    TextFormField(
                      controller: _controllerEmail,
                      enabled: _isEditing,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter email';
                        final v = value.trim();
                        if (!(v.contains('@') && v.contains('.'))) {
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
                      decoration: _inputDecoration(
                        label: 'Password',
                        icon: Icons.password_outlined,
                      ).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Enter password'
                          : null,
                    ),

                    const SizedBox(height: 30),

                    _filledActionButton(
                      label: 'Change Password',
                      icon: Icons.lock_reset,
                      onPressed: _changePasswordDialog,
                    ),
                    const SizedBox(height: 10),

                    _filledActionButton(
                      label: 'Logout',
                      icon: Icons.logout,
                      background: Colors.red,
                      onPressed: _logout,
                    ),
                    const SizedBox(height: 10),

                    _filledActionButton(
                      label: 'Delete Account',
                      icon: Icons.delete_forever,
                      background: Colors.black,
                      onPressed: _deleteAccount,
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

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(40)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(40),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
    );
  }

  Widget _filledActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? background,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background ?? Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
          elevation: 2,
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
