import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/screens/ChatRoom.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/ControllerAndroidService.dart' as serviceAndroid;
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
            ));
      }
    });

    polling.setRoomList(pollingRoomList);
    polling.setUserID(userInfo.userID.toString());
    if (io.Platform.isAndroid) {
      serviceAndroid.runService();
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

class RecentChat extends StatelessWidget {
  final String friendName;
  final String userID;
  final String userName;
  final String roomID;
  final String friendID;

  RecentChat(
      {Key key,
      this.friendName,
      this.userID,
      this.userName,
      this.roomID,
      this.friendID})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('click $roomID');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                      friendName: friendName,
                      userID: userID,
                      userName: userName,
                      roomID: roomID,
                      friendID: friendID,
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
                  backgroundImage: AssetImage('assets/005.png'),
                ),
                SizedBox(width: 10),
                Container(
                  child: Text(friendName,
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
