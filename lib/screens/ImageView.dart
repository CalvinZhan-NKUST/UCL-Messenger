
import 'package:photo_view/photo_view.dart';
import 'package:flutter/material.dart';


class ImageApp extends StatefulWidget {
  @override
  _ImageAppState createState() => _ImageAppState();
}

class _ImageAppState extends State<ImageApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PhotoView(
        imageProvider: const NetworkImage(
            'https://chatapp.54ucl.com:5000/images/acd2a956-96a2-11eb-b942-00224899e61e.jpg'),
        minScale: 0.5,
        maxScale: 3.0,
        enableRotation: false,
      ),
    );
  }
}