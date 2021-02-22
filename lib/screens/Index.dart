import 'dart:convert';

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
  static const BasicMessageChannel<String> platform = BasicMessageChannel<String>(_channel, StringCodec());


  @override
  void initState() {
    super.initState();
    _roomList.clear();

    polling.setRoomList(globalString.GlobalString.userRoomList);
    polling.setUserID(globalString.GlobalString.userID);
    makeFriendChatList();
    print('Index init');
    getMsgPara();
    serviceAndroid.runService();
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



  void getMsgPara() async{
    var url = '${globalString.GlobalString.ipMysql}/getConfigPara';
    print(url);
    var response =
        await http.post(url, body: {'UserID': globalString.GlobalString.userID});
    print('getConfigPara body:${response.body}');
    res = jsonDecode(response.body);
    print(res['MsgPara']);
    globalString.GlobalString.msgPara = res['MsgPara'];
//    globalString.GlobalString.setPara(res['MsgPara']);
    print('globalMsgPara:${globalString.GlobalString.msgPara}');
  }

  void makeFriendChatList() {
//    widget.friendList.insert(0,'value'); 未來可以新增至第一位
//    widget.nameList.reversed 反過來


    print('好友人數：${globalString.GlobalString.userNameList.length}');
    for (var i = globalString.GlobalString.userNameList.length - 1; i >= 0; i--) {
      _roomList.insert(
          0,
          RecentChat(
              friendName: globalString.GlobalString.userNameList[i],
              userID: globalString.GlobalString.userID,
              userName: globalString.GlobalString.userName,
              roomID: globalString.GlobalString.userRoomList[i],
              friendID: globalString.GlobalString.userIDList[i]));
      print(i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        margin: EdgeInsets.all(10),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.45,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            color: Colors.blueAccent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/005.png'),
                ),
                Container(
                  child: Text(friendName,
                      style: TextStyle(
                          fontSize: 32.0,
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
