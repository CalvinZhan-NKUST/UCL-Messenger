import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/HomePage.dart';
import 'package:flutter_msg/screens/BottomNavigation.dart';
import 'package:flutter_msg/screens/CameraView.dart';
import 'package:flutter_msg/screens/ImageView.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        "/login":(context)=>new MyApp(),
        "/index":(context)=>new BottomNavigationController()
      },
      title: 'UCL Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
//        primaryColor: Color(0xFF1b3958),
        primaryColor: Colors.blueAccent,
        accentColor: Color(0xFFFFFFFF),
      ),
      home: ImageApp(),
    );
  }
}