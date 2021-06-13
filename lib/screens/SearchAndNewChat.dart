import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/LongPolling.dart';
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/Model.dart';

class SearchAndNewChat extends StatefulWidget {
  @override
  _SearchAndNewChat createState() => _SearchAndNewChat();
}

final List<Widget> _friends = []; // 建立一個空陣列
var _dataBaseRoomList = new List();
var _dataBaseUserInfo = new List();

@override
class _SearchAndNewChat extends State<SearchAndNewChat> {
  final TextEditingController _searchController = new TextEditingController();
  String _textInput = '';

  void getDataBaseInfo() async {
    _dataBaseUserInfo = await DB.selectUser();
    _dataBaseRoomList = await DB.selectRoomList();
  }

  void initState() {
    super.initState();
    _friends.clear();
    getDataBaseInfo();
  }

  void dispose(){
    _friends.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
        ),
        child: Column(
          children: <Widget>[
            Container(
                margin: const EdgeInsets.only(top: 40, left: 5.0),
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 10),
                    Flexible(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(16.0),
                            border: OutlineInputBorder(),
                            hintText: '搜尋'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.search_rounded,
                        size: 36,
                      ),
                      onPressed: () {
                        _textInput = _searchController.text.trim();
                        if (_textInput.isEmpty == false) {
                          _submitText(_searchController.text.trim());
                          _searchController.clear();
                        }
                      },
                    ),
                    SizedBox(width: 10),
                  ],
                )),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 5,left: 10,right: 10,bottom: 5),
                reverse: false,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) => _friends[index],
                itemCount: _friends.length,
              ),
            ),
          ],
        ),
      ),
      onWillPop: () {
        print('onWillScope');
        SystemNavigator.pop();
        return null;
      },
    );
  }

  _submitText(String inputText) async {
    setState(() {
      _friends.clear();
    });
    var userInfo = _dataBaseUserInfo[0];
    String url = '${globalString.GlobalString.ipMysql}/searchUser';
    var response = await http.post(Uri.parse(url),
        body: {'searchValue': inputText, 'UserID': userInfo.userID.toString()});
    print(response.body);

    var responseJson = jsonDecode(response.body)['res'] as List;
    List<FriendResult> responseObject =
        responseJson.map((tagJson) => FriendResult.fromJson(tagJson)).toList();
    for (int i = 0; i < responseObject.length; i++) {
      print('ID:${responseObject[i].userID}');
      setState(() {
        _friends.insert(
            0,
            FriendSearchList(
                userName: responseObject[i].userName,
                userImgURL: responseObject[i].userImgURL,
                userID: responseObject[i].userID.toString()));
      });
    }
  }
}

class FriendSearchList extends StatefulWidget {
  final String userName;
  final String userImgURL;
  final String userID;
  FriendSearchList({Key key, this.userName, this.userImgURL, this.userID})
      : super(key: key);

  _FriendSearchList createState() => _FriendSearchList();

}

class _FriendSearchList extends State<FriendSearchList> {
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.userImgURL != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(10.0),
          topRight: Radius.circular(10.0),
          topLeft: Radius.circular(10.0),
          bottomLeft: Radius.circular(10.0),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.45,
          padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [Colors.blue, Colors.grey]
              )
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 10),
              CircleAvatar(
                radius: 30,
                backgroundImage: setImage
                    ? NetworkImage('${widget.userImgURL}')
                    : AssetImage('assets/005.png'),
              ),
              Container(
                child: Text(widget.userName,
                    style: TextStyle(
                        fontSize: 32.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none)),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.add_box_outlined),
                    iconSize: 36,
                    color: Color(0xfff8f8ff),
                    onPressed: () {
                      _clickAdd(widget.userName, widget.userID, context, widget.userImgURL);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clickAdd(String userName, String userID, BuildContext context, String userImageUrl) async{
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('請稍候...'),
          );
        });
    final scaffold = Scaffold.of(context);
    var userInfo = _dataBaseUserInfo[0];
    int _roomExist = 0;
    for (int i = 0; i < _dataBaseRoomList.length; i++) {
      if (userID == (_dataBaseRoomList[i].userID).toString()) {
        Navigator.of(context).pop();
        _roomExist=1;
        print('$userID, ${_dataBaseRoomList[i].userID}');
        scaffold.showSnackBar(SnackBar(
          content: Text("聊天室已存在"),
          action: SnackBarAction(
              label: '確定', onPressed: scaffold.hideCurrentSnackBar),
        ));
      }
    }
    if (_roomExist==0){
      String _userList = userID + ',' + userInfo.userID.toString() + ',';
      String url = '${globalString.GlobalString.ipMysql}/createNewChatRoom';
      var response = await http.post(Uri.parse(url),
          body: {'UserID':userInfo.userID.toString(),'UserIDList': _userList, 'RoomType': '1', 'RoomName':'none'});
      Map<String, dynamic> resAddNewRoom;
      resAddNewRoom = jsonDecode(response.body);
      print('RoomID:${resAddNewRoom['RoomID']}, LastMsgTime:${resAddNewRoom['LastMsgTime']}');
      DB.insertSingleRoom(resAddNewRoom['RoomID'], userName, userID, userImageUrl, resAddNewRoom['LastMsgTime'], 'none');
      shutDownLongPolling();
      setLongPolling();
      Navigator.of(context).pop();
      scaffold.showSnackBar(SnackBar(
        content: Text("聊天室新增完畢"),
        action: SnackBarAction(
            label: '確定', onPressed: scaffold.hideCurrentSnackBar),
      ));
    }
  }

  void setLongPolling() async {
    await Future.delayed(Duration(seconds: 1));
    var dataBaseRoomList = new List();
    var pollingRoomList = new List();

    dataBaseRoomList = await DB.selectRoomList();
    for (var i = dataBaseRoomList.length - 1; i >= 0; i--) {
      var room = dataBaseRoomList[i];
      pollingRoomList.add(room.roomID);
    }
    setRoomList(pollingRoomList);
  }
}


