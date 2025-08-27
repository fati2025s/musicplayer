import 'dart:convert';
import 'package:flutter/material.dart';

class ProfileImageSlider extends StatefulWidget {
  final List<String> initialBase64;
  final int initialIndex;

  const ProfileImageSlider({
    Key? key,
    required this.initialBase64,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<ProfileImageSlider> createState() => _ProfileImageSliderState();
}

class _ProfileImageSliderState extends State<ProfileImageSlider> {
  late List<String> _base64Images;
  late int _currentIndex;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _base64Images = List.from(widget.initialBase64);
    _currentIndex = widget.initialIndex.clamp(0, _base64Images.isEmpty ? 0 : _base64Images.length - 1);
    _controller = PageController(
      viewportFraction: 0.7,
      initialPage: _currentIndex,
    );
  }

  void _removeCurrentImage() {
    if (_base64Images.isEmpty) return;

    setState(() {
      _base64Images.removeAt(_currentIndex);
      if (_base64Images.isEmpty) {
        Navigator.pop(context);
      } else {
        _currentIndex = _currentIndex.clamp(0, _base64Images.length - 1);
        _controller.jumpToPage(_currentIndex);
      }
    });
  }

  void _setCurrentImage() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ عکس پروفایل انتخاب شد")),
      );
    }
  }

  Widget _buildImageItem(String base64) {
    if (base64.isEmpty) {
      return const Center(child: Text("تصویر موجود نیست"));
    }
    try {
      final bytes = base64Decode(base64);
      return Image.memory(bytes, fit: BoxFit.contain);
    } catch (_) {
      return const Center(child: Text("خطا در بارگذاری تصویر"));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Pictures"),
        actions: [
          if (_base64Images.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _removeCurrentImage,
            ),
        ],
      ),
      body: _base64Images.isEmpty
          ? const Center(child: Text("هیچ عکسی موجود نیست"))
          : Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _base64Images.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildImageItem(_base64Images[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text("انتخاب به عنوان پروفایل"),
            onPressed: _setCurrentImage,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
