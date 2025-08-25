// ===================== lib/screens/user_profile_screen.dart =====================
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/SocketService.dart';
import '../service/Playlist.dart';

class UserProfileScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final SocketService socketService;

  const UserProfileScreen({
    super.key,
    required this.onToggleTheme,
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

  late PlaylistService playlistService;

  @override
  void initState() {
    super.initState();
    playlistService = PlaylistService(widget.socketService);
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

        if (payload.isNotEmpty) {
          final resp = await widget.socketService.updateProfile(payload);
          final success = resp['status'] == 'success';
          if (!success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Failed to update profile on server')),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing profile to server: $e');
    }

    await prefs.setString('username', newUsername);
    await prefs.setString('email', newEmail);
    await prefs.setString('password', newPassword);
    if (_profileImage != null) {
      await prefs.setString('profileImage', _profileImage!.path);
    }

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
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

    try {
      if (widget.socketService.isConnected) {
        final resp = await widget.socketService.uploadProfilePicture(file.path);
        final success = resp['status'] == 'success';
        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload profile picture')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error while uploading picture')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      if (widget.socketService.isConnected) {
        await widget.socketService.logout();
      }
    } catch (e) {
      debugPrint('Error in logout: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  Future<void> _changePasswordDialog() async {
    final oldController = TextEditingController();
    final newController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldController,
              decoration: const InputDecoration(labelText: 'Old Password'),
              obscureText: true,
            ),
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
          TextButton(
            child: const Text('Change'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Password changed successfully'
                            : 'Failed to change password',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Network error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sharePlaylistDialog() async {
    final usernameController = TextEditingController();
    final playlistIdController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: playlistIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Playlist ID'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Target Username'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            child: const Text('Share'),
            onPressed: () async {
              try {
                final success = await playlistService.sharePlaylist(
                  int.tryParse(playlistIdController.text) ?? 0,
                  usernameController.text.trim(),
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Playlist shared successfully'
                          : 'Failed to share playlist'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Network error')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveUserData();
              } else {
                setState(() => _isEditing = true);
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
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _controllerEmail,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter email';
                  final v = value.trim();
                  if (!(v.contains('@') && v.contains('.'))) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _controllerPassword,
                enabled: _isEditing,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.password_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? 'Enter password' : null,
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.lock_reset, color: Colors.white),
                label: const Text('Change Password',
                    style: TextStyle(color: Colors.white)),
                onPressed: _changePasswordDialog,
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text('Share Playlist',
                    style: TextStyle(color: Colors.white)),
                onPressed: _sharePlaylistDialog,
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size.fromHeight(50),
                ),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: _logout,
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
