import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlackProfileImageSlider extends StatefulWidget {
  final List<File> initialImages;
  final int initialIndex;

  const BlackProfileImageSlider({required this.initialImages, this.initialIndex = 0, Key? key}) : super(key: key);

  @override
  _ProfileImageSliderState createState() => _ProfileImageSliderState();
}

class _ProfileImageSliderState extends State<BlackProfileImageSlider> {
  late List<File> _images;
  late int _currentIndex;
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex, viewportFraction: 0.7);
  }

  void _removeCurrentImage() {
    if (_images.isEmpty) return;

    setState(() {
      _images.removeAt(_currentIndex);
      if (_images.isEmpty) {
        Navigator.pop(context,_images);
      } else {
        _currentIndex = _currentIndex.clamp(0, _images.length - 1);
        _controller.jumpToPage(_currentIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final isCurrent = index == _currentIndex;
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: isCurrent ? 8 : 16, vertical: isCurrent ? 20 : 40),
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  _images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}