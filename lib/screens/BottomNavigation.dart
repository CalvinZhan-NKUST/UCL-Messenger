import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/Index.dart';
import 'package:flutter_msg/screens/PersonalFile.dart';
import 'package:flutter_msg/screens/SearchAndNewChat.dart';
import 'package:flutter_msg/screens/FriendList.dart';
import 'package:flutter_msg/GlobalVariable.dart' as globalString;

class BottomNavigationController extends StatefulWidget {
  BottomNavigationController({Key key}) : super(key: key);

  @override
  _BottomNavigationControllerState createState() =>
      _BottomNavigationControllerState();
}

class _BottomNavigationControllerState
    extends State<BottomNavigationController> {
  int _currentNum = 0; //預設值
  final pages = [
    IndexScreen(),
    SearchAndNewChat(),
    FriendList(),
    PersonalPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentNum],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded, size: 36), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 36), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 36), label: ''),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_box_rounded, size: 36), label: ''),
        ],
        unselectedItemColor: Color(0xffc0c0c0),
        currentIndex: _currentNum, //目前選擇頁索引值
        selectedItemColor: Color(0xff4682b4), //選擇頁顏色
        onTap: _onItemClick, //BottomNavigationBar 按下處理事件
      ),
    );
  }

  //BottomNavigationBar 按下處理事件，更新設定當下索引值
  void _onItemClick(int index) {
    setState(() {
      _currentNum = index;
    });
  }
}
