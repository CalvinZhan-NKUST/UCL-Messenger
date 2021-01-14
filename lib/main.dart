import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/Login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCL Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
//        primaryColor: Color(0xFF1b3958),
        primaryColor: Colors.blueAccent,
        accentColor: Color(0xFFFFFFFF),
      ),
      home: HomeScreen(),
    );
  }
}