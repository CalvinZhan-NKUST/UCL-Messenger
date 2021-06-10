import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/LongPolling.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;

class FriendList extends StatefulWidget {
  @override
  _FriendList createState() => _FriendList();
}

final List<Widget> _friendsList = []; // 建立一個空陣列
var _dataBaseFriendList = new List();
var _dataBaseUserInfo = new List();
var _friendCheckList = new Map();

@override
class _FriendList extends State<FriendList> {
  final TextEditingController _roomNameController = new TextEditingController();
  String _textInput = '';

  void getDataBaseFriendList() async {
    _dataBaseFriendList = await DB.selectRoomList();
    _dataBaseUserInfo = await DB.selectUser();
    for (int i = 0; i < _dataBaseFriendList.length; i++) {
      if (_dataBaseFriendList[i].userID.toString() != '0') {
        setState(() {
          _friendCheckList['${_dataBaseFriendList[i].userID.toString()}'] =
              'false';
          _friendsList.insert(
              0,
              FriendListWidget(
                  userID: _dataBaseFriendList[i].userID.toString(),
                  userName: _dataBaseFriendList[i].userName,
                  userImgURL: 'none'));
        });
      }
    }
  }

  void initState() {
    super.initState();
    _friendsList.clear();
    _dataBaseFriendList.clear();
    _friendCheckList.clear();
    getDataBaseFriendList();
  }

  void dispose() {
    _friendsList.clear();
    _dataBaseFriendList.clear();
    _friendCheckList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Container(
        child: Column(children: <Widget>[
          SizedBox(height: 40),
          Row(
            children: <Widget>[
              SizedBox(width: 5),
              Flexible(
                child: TextField(
                  controller: _roomNameController,
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.all(16.0),
                      border: OutlineInputBorder(),
                      hintText: '請輸入群組名稱'),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.add_box_outlined,
                  size: 36,
                  color: Color(0xff808080),
                ),
                onPressed: () {
                  _textInput = _roomNameController.text.trim();
                  if (_textInput.isEmpty == false) {
                    _submitText(_roomNameController.text.trim());
                    _roomNameController.clear();
                  }
                },
              ),
              SizedBox(width: 5),
            ],
          ),
          Expanded(
              child: ListView.builder(
            padding: const EdgeInsets.only(top: 5, bottom: 5),
            reverse: false,
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) => _friendsList[index],
            itemCount: _friendsList.length,
          )),
        ]),
      ),
      onWillPop: () {
        SystemNavigator.pop();
        return null;
      },
    );
  }

  void _submitText(String roomName) async {
    final scaffold = Scaffold.of(context);
    String userIDList = '';
    bool pass = true;
    for (int i = 0; i < _dataBaseFriendList.length; i++) {
      if (_dataBaseFriendList[i].userName == roomName) {
        scaffold.showSnackBar(SnackBar(
          content: Text("已有相同的群組"),
          action: SnackBarAction(
              label: '確定', onPressed: scaffold.hideCurrentSnackBar),
        ));
        pass = false;
      }

      if (_dataBaseFriendList[i].userID.toString() != '0' &&
          _friendCheckList[_dataBaseFriendList[i].userID.toString()] !=
              'false') {
        print(_dataBaseFriendList[i].userID.toString() +
            ' , ' +
            _friendCheckList[_dataBaseFriendList[i].userID.toString()]);
        userIDList += '${_dataBaseFriendList[i].userID.toString()},';
      }
    }

    if (userIDList != '' && pass == true) {
      userIDList += '${_dataBaseUserInfo[0].userID.toString()},';
      var url = '${globalString.GlobalString.ipMysql}/createNewChatRoom';
      var response = await http.post(Uri.parse(url), body: {
        'UserID':_dataBaseUserInfo[0].userID.toString(),
        'UserIDList': userIDList,
        'RoomType': '2',
        'RoomName': roomName
      });
      Map<String, dynamic> resAddNewRoom;
      resAddNewRoom = jsonDecode(response.body);
      DB.insertSingleRoom(resAddNewRoom['RoomID'], roomName, '0', 'none', resAddNewRoom['LastMsgTime']);
      shutDownLongPolling();
      setLongPolling();
      scaffold.showSnackBar(SnackBar(
        content: Text("群組新增完畢"),
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

class FriendListWidget extends StatefulWidget {
  final String userName;
  final String userImgURL;
  final String userID;

  FriendListWidget({Key key, this.userName, this.userImgURL, this.userID})
      : super(key: key);

  @override
  _FriendListWidget createState() => _FriendListWidget();
}

@override
class _FriendListWidget extends State<FriendListWidget> {
  bool saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(5),
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
              gradient: LinearGradient(colors: [Colors.blue, Colors.grey])),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(width: 10),
              CircleAvatar(
                radius: 25,
                backgroundImage: AssetImage('assets/005.png'),
              ),
              SizedBox(width: 10),
              Container(
                child: Text(widget.userName,
                    style: TextStyle(
                        fontSize: 28.0,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none)),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Checkbox(
                    value: saving,
                    onChanged: (value) {
                      setState(() {
                        saving = !saving;
                        _friendCheckList['${widget.userID.toString()}'] =
                            saving.toString();
                      });
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
}
