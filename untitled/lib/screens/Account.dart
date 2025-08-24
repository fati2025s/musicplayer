import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'Login.dart';
import 'ProfilePicture.dart';
import 'Signup.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String username = "User123";
  String email = "user@example.com";
  File? _image;
  List<File> images = [];
  final ImagePicker _picker = ImagePicker();

  void _changeName() {
    TextEditingController nameController = TextEditingController(
        text: username);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "New Username",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                //_changeUsername();
                setState(() {
                  username = nameController.text;
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "change_name") {
                _changeName();
              }
            },
            itemBuilder: (context) =>
            [
              const PopupMenuItem(
                value: "change_name",
                child: Text("Change Name"),
              ),
            ],
          )
        ],
      ),
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              color: Colors.red,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final updatedImages = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileImageSlider(initialImages: images),
                            ),
                          );
                          if (updatedImages != null) {
                            setState(() {
                              images = List<File>.from(updatedImages);
                              _image = images.isNotEmpty ? images.last : null;
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: images.isNotEmpty
                              ? FileImage(_image!) as ImageProvider
                              : const AssetImage('assets/profile.jpg'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        username,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_a_photo_outlined, color: Colors.black),
                      onPressed: () async {
                        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            _image = File(pickedFile.path);
                          });
                          print("عکس انتخاب شد: ${pickedFile.path}");
                          images.add(_image!);
                        } else {
                          print("هیچ عکسی انتخاب نشد.");
                        }
                      },
                    ),
                  ],
                ),

                //const SizedBox(height: 20),
                Expanded(
                  child: Material(
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.person_add),
                          title: const Text("Add Account"),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Signup()),
                            );
                          },
                        ),
                        const Spacer(),
                        ListTile(
                          leading: const Icon(Icons.delete, color: Colors.red),
                          title: const Text("حذف حساب کاربری", style: TextStyle(
                              color: Colors.red)),
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text("خروج از حساب", style: TextStyle(
                              color: Colors.red)),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Login()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}