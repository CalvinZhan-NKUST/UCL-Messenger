import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/SQLite.dart' as DB;

class SearchAndNewChat extends StatefulWidget {
  @override
  _SearchAndNewChat createState() => _SearchAndNewChat();
}

@override
class _SearchAndNewChat extends State<SearchAndNewChat> {
  final List<Widget> _friends = []; // 建立一個空陣列
  final TextEditingController _searchController = new TextEditingController();
  String _textInput = '';
  var dataBaseUserInfo = new List();

  void getUserInfo() async {
    dataBaseUserInfo = await DB.selectUser();
  }

  void initState() {
    super.initState();
    getUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(globalString.GlobalString.searchUser),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Container(
                margin: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(16.0),
                            border: OutlineInputBorder(),
                            hintText: 'Type something...'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _textInput = _searchController.text.trim();
                        if (_textInput.isEmpty == false) {
                          _submitText(_searchController.text.trim());
                        }
                      },
                    ),
                  ],
                )),
            SizedBox(height: 5),
            Expanded(
              child: ListView.builder(
                padding: new EdgeInsets.all(15.0),
                reverse: false,
                //加入reverse，讓它反轉
//        controller: _scrollController,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) => _friends[index],
                itemCount: _friends.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _submitText(String inputText) async {
    var userInfo = dataBaseUserInfo[0];
    String url = '${globalString.GlobalString.ipMysql}/searchUser';
    var response = await http.post(url, body: {'searchValue': inputText, 'UserID': userInfo.userID.toString()});
    print(response.body);

    var responseJson = jsonDecode(response.body)['res'] as List;
    List<FriendResult> responseObject =
    responseJson.map((tagJson) => FriendResult.fromJson(tagJson)).toList();
    var userName = responseObject[0];
    print('UserName:${userName.userName}');
  }
}

class FriendResult {
  int msgID;
  String userName;
  String account;
  String userImgURL;

  FriendResult(this.msgID, this.userName, this.account, this.userImgURL);

  factory FriendResult.fromJson(dynamic json) {
    return FriendResult(
        json['MsgID'] as int,
        json['UserName'] as String,
        json['Account'] as String,
        json['userIngURL'] as String
    );
  }

  @override
  String toString() {
    return '{ ${this.msgID}, ${this.userName}, ${this.account}, ${this.userImgURL}}';
  }
}