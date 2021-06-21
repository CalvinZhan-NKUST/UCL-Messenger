import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/Model.dart';
import 'package:flutter_msg/SendMessage.dart';
import 'package:flutter_msg/screens/ChatRoom.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/MethodChannel.dart' as callMethodChannel;
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/widget/RecentChatWidget.dart';

class IndexScreen extends StatefulWidget {
  IndexScreen({Key key}) : super(key: key);

  @override
  IndexScreenState createState() => IndexScreenState();
}

List<Widget> _roomList = [];
Timer checkChatRoom;

class IndexScreenState extends State<IndexScreen> {
  void checkRoomNum() {
    checkChatRoom = new Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });
  }

  void refreshChatRoomList() async {
    print('重新整理聊天室清單');
    await DB.selectUser();
    await DB.selectRoomList();
    makeFriendChatList();
  }

  Future<void> checkMessageSend() async {
    List<RoomList> checkChatRoomAction = new List();
    checkChatRoomAction = await DB.selectRoomList();
    for (int i = 0; i < checkChatRoomAction.length; i++) {
      var roomAction = checkChatRoomAction[i];
      if (roomAction.action.toString() == 'uploading') {
        List<MessageUpdate> updateMsg = new List();
        updateMsg = await DB.selectUpdateMsg(roomAction.roomID.toString());
        print('有尚未上傳的訊息');
        sendMessage(
            updateMsg[0].roomID.toString(),
            updateMsg[0].sendUserID.toString(),
            updateMsg[0].sendName,
            updateMsg[0].receiveName,
            updateMsg[0].receiveUserID.toString(),
            updateMsg[0].text,
            updateMsg[0].msgType,
            updateMsg[0].dateTime,
            updateMsg[0].roomMsgSN,
            updateMsg[0].sendUserToken);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _roomList.clear();
    makeFriendChatList();
    checkRoomNum();
    checkMessageSend();
    DB.selectUser();
    DB.selectRoomList();
    DB.updateLocate('Index');
    print('Index init');
  }

  void dispose() {
    _roomList.clear();
    DB.updateLocate('none');
    print('Index dispose');
    if (checkChatRoom != null) {
      checkChatRoom.cancel();
      checkChatRoom = null;
    }
    super.dispose();
  }

  void getMsgPara() async {

    List<UserInfo> user = new List();
    user = await DB.selectUser();

    var url = '${globalString.GlobalString.ipMysql}/getConfigPara';
    print(url);
    var response = await http.post(Uri.parse(url),
        body: {'UserID': user[0].userID.toString(), 'Token':user[0].token});
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

    dataBaseRoomList.clear();
    dataBaseUserInfo.clear();
    pollingRoomList.clear();
    _roomList.clear();

    print('從DB撈出來的清單：${await DB.selectRoomList()}');
    dataBaseRoomList = await DB.selectRoomList();

    dataBaseUserInfo = await DB.selectUser();
    var userInfo = dataBaseUserInfo[0];
    globalString.GlobalString.userName = userInfo.userName;
    globalString.GlobalString.userID = userInfo.userID.toString();
    getMsgPara();
    for (var i = dataBaseRoomList.length - 1; i >= 0; i--) {
      var room = dataBaseRoomList[i];
      pollingRoomList.add(room.roomID);
      print('Updating new room list.');
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
            token: userInfo.token.toString(),
          ));
    }

    if (io.Platform.isAndroid) {
      callMethodChannel.runService();
    } else if (io.Platform.isIOS) {
      polling.setRoomList(pollingRoomList);
      polling.setUserID(userInfo.userID.toString(), userInfo.token.toString());
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
