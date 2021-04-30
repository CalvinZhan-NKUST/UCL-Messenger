import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/screens/ChatRoom.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/MethodChannel.dart' as callMethodChannel;
import 'package:flutter_msg/SQLite.dart' as DB;

class IndexScreen extends StatefulWidget {
  IndexScreen({Key key}) : super(key: key);

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

List<Widget> _roomList = [];
String _newMsg = '';

class _IndexScreenState extends State<IndexScreen> {
  static const String _channel = 'sendUserID';
  static const BasicMessageChannel<String> platform =
      BasicMessageChannel<String>(_channel, StringCodec());

  @override
  void initState() {
    super.initState();
    _roomList.clear();
    makeFriendChatList();
    DB.selectUser();
    DB.selectRoomList();
    print('userID:${globalString.GlobalString.userID}');
    print('Index init');
  }

  @override
  void deactivate() {
    _roomList.clear();
    print('deactivate');
    super.deactivate();
  }

  Future<void> dispose() async {
    _roomList.clear();
    print('Index dispose');
    super.dispose();
  }

  void getMsgPara() async {
    var url = '${globalString.GlobalString.ipMysql}/getConfigPara';
    print(url);
    var response = await http
        .post(url, body: {'UserID': globalString.GlobalString.userID});
    print('getConfigPara body:${response.body}');
    res = jsonDecode(response.body);
    print(res['MsgPara']);
    globalString.GlobalString.msgPara = res['MsgPara'];
    print('globalMsgPara:${globalString.GlobalString.msgPara}');
  }

  Future<void> makeFriendChatList() async {
    var dataBaseRoomList = new List();
    var dataBaseUserInfo = new List();
    var pollingRoomList = new List();

    print('從DB撈出來的清單：${await DB.selectRoomList()}');
    dataBaseRoomList = await DB.selectRoomList();

    dataBaseUserInfo = await DB.selectUser();
    var userInfo = dataBaseUserInfo[0];
    globalString.GlobalString.userName = userInfo.userName;
    globalString.GlobalString.userID = userInfo.userID.toString();
    getMsgPara();
    setState(() {
      for (var i = dataBaseRoomList.length - 1; i >= 0; i--) {
        var room = dataBaseRoomList[i];
        pollingRoomList.add(room.roomID);
        _roomList.insert(
            0,
            RecentChat(
              friendID: room.userID.toString(),
              friendName: room.userName,
              roomID: room.roomID.toString(),
              userID: userInfo.userID.toString(),
              userName: userInfo.userName,
              friendImageUrl: room.userImageUrl.toString(),
              userImageUrl: userInfo.userImageURL.toString(),
            ));
      }
    });

    if (io.Platform.isAndroid) {
      callMethodChannel.runService();
    } else if (io.Platform.isIOS){
      polling.setRoomList(pollingRoomList);
      polling.setUserID(userInfo.userID.toString());
    }
    print('好友人數：${dataBaseRoomList.length}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Container(
        decoration: BoxDecoration(
          color: Color(0xfff5f5f5),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
        ),
        child: ListView.builder(
          reverse: false,
          itemCount: _roomList.length,
          itemBuilder: (context, index) => _roomList[index],
        ),
      ),
      onWillPop: () {
        print('onWillScope');
        SystemNavigator.pop();
        return null;
      },
    );
  }
}

class RecentChat extends StatefulWidget {
  final String friendName;
  final String userID;
  final String userName;
  final String userImageUrl;
  final String roomID;
  final String friendID;
  final String friendImageUrl;

  RecentChat({Key key,
    this.friendName,
    this.userID,
    this.userName,
    this.userImageUrl,
    this.roomID,
    this.friendID,
    this.friendImageUrl})
      : super(key: key);

  _RecentChatState createState() => _RecentChatState();

}

class _RecentChatState extends State<RecentChat>{
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.friendImageUrl != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('click $widget.roomID');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                      friendName: widget.friendName,
                      userID: widget.userID,
                      userName: widget.userName,
                      roomID: widget.roomID,
                      friendID: widget.friendID,
                      userImageUrl: widget.userImageUrl,
                      friendImageUrl: widget.friendImageUrl,
                    )));
      },
      child: Container(
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
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.grey]
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Text(''),
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.friendImageUrl}')
                      : AssetImage('assets/005.png'),
                ),
                SizedBox(width: 10),
                Container(
                  child: Text(widget.friendName,
                      style: TextStyle(
                          fontSize: 28.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none)),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: Text(_newMsg,
                        style: TextStyle(
                            fontSize: 24.0,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
