import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/Index.dart';
import 'package:flutter_msg/screens/PersonalFile.dart';
import 'package:flutter_msg/screens/SearchAndNewChat.dart';
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
    PersonalPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[_currentNum],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded), label: '聊天室清單'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_rounded), label: '搜尋好友&新增聊天室'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_box_rounded), label: '個人資料'),
        ],
        currentIndex: _currentNum, //目前選擇頁索引值
        fixedColor: Colors.amber, //選擇頁顏色
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
