import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class ProfileImageSlider extends StatefulWidget {
  final List<String> initialImages;
  final int initialIndex;
  final Future<void> Function(int index)? onDelete;
  final Future<void> Function(int index)? onSetCurrent;

  const ProfileImageSlider({
    required this.initialImages,
    this.initialIndex = 0,
    this.onDelete,
    this.onSetCurrent,
    Key? key,
  }) : super(key: key);

  @override
  _ProfileImageSliderState createState() => _ProfileImageSliderState();
}

class _ProfileImageSliderState extends State<ProfileImageSlider> {
  late List<String> _images;
  late int _currentIndex;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
    _currentIndex = widget.initialIndex;
    _controller =
        PageController(initialPage: _currentIndex, viewportFraction: 0.7);
  }

  Future<void> _removeCurrentImage() async {
    if (_images.isEmpty) return;

    if (widget.onDelete != null) {
      await widget.onDelete!(_currentIndex);
    }
    if (!mounted) return;
    setState(() {
      _images.removeAt(_currentIndex);
      if (_images.isEmpty) {
        Navigator.pop(context, _images);
      } else {
        _currentIndex = _currentIndex.clamp(0, _images.length - 1);
        _controller.jumpToPage(_currentIndex);
      }
    });
  }

  Future<void> _setCurrentImage(int index) async {
    if (widget.onSetCurrent != null) {
      await widget.onSetCurrent!(index);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("این عکس به عنوان پروفایل انتخاب شد")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pictures"),
        actions: [
          if (_images.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _removeCurrentImage,
            ),
        ],
      ),
      body: _images.isEmpty
          ? Center(child: Text("هیچ عکسی موجود نیست"))
          : PageView.builder(
        controller: _controller,
        itemCount: _images.length,
        onPageChanged: (index) =>
            setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return Image(
            image: MemoryImage(base64Decode(_images[index])),
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
