import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/SQLite.dart' as DB;

class FriendList extends StatefulWidget {
  @override
  _FriendList createState() => _FriendList();
}


@override
class _FriendList extends State<FriendList> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Row(),
      onWillPop: (){
        SystemNavigator.pop();
        return null;
      },
    );
  }
}