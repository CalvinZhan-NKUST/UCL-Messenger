import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/SQLite.dart' as sqlite;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter_msg/screens/Index.dart' as Index;
import 'package:flutter_msg/MethodChannel.dart' as callMethodChannel;
import 'package:flutter_msg/Model.dart';


var period = const Duration(seconds: 60);
bool timeStart = false;
var clientRoomList = new List();
int _times = 0;
Timer _pollingTimer;
Map<String, String> client = {};
String _userID = '';
String locateRoomID = '';

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();
final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();
final flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('nkust');
final IOSInitializationSettings initializationSettingsIOS =
    IOSInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        onDidReceiveLocalNotification:
            (int id, String title, String body, String payload) async {
          didReceiveLocalNotificationSubject.add(ReceivedNotification(
              id: id, title: title, body: body, payload: payload));
        });

final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

void requestPermissions() {
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

void setRoomList(List roomList) {
  String _room = '';
  for (int i = 0; i < roomList.length; i++) {
    _room += '${roomList[i]},';
    clientRoomList.add(roomList[i]);
  }
  longPolling(_room);
  print(_room);
  print('setRoomList');
}

void setUserID(String chatUserID) {
  _userID = chatUserID;
  print('chatUser:$chatUserID,UserID:$_userID');
}

void setLocateRoomID(String roomID) {
  locateRoomID = roomID;
}

void longPolling(String roomNotify) {
  print('進入長輪詢：$timeStart');
  if (timeStart == false) {
    timeStart = true;
    _pollingTimer = new Timer.periodic(period, (Timer timer) async {
      checkRoomNum();
      var url = '${globalString.GlobalString.ipRedis}/notify';
      var response = await http.post(Uri.parse(url), body: {'RoomIDList': roomNotify});
      print('LongPolling response body:${response.body}');
      var tagObjsJson = jsonDecode(response.body)['res'] as List;
      List<RoomMaxSN> tagObjs =
          tagObjsJson.map((tagJson) => RoomMaxSN.fromJson(tagJson)).toList();
      print(tagObjs);
    });
  }
}

void shutDownLongPolling() {
  timeStart = false;
  if (_pollingTimer != null) {
    _pollingTimer.cancel();
    _pollingTimer = null;
  }
}

//比較每個Room的訊息編號
class CompareMaxSN {
  void setClientSN(String roomID, String maxSN) {
    client[roomID] = maxSN;
    print('Set Cache:$roomID,$maxSN');
    print('Cache長度：${client.length}');
  }

  void compareMsgSN(String roomID, String maxSN) {
    print('比較Server:$roomID,$maxSN;ClientSN:${client[roomID]}');
    if (int.parse(maxSN) > int.parse(client[roomID])) {
      int msgPara = int.parse(maxSN) - int.parse(client[roomID]);
      getNewestMsg(roomID, client[roomID], msgPara.toString());
      sqlite.updateMsgSN(roomID, maxSN);
      sqlite.setClientCache();
      print('進行取得最新訊息，並且需要通知！！！');
    }
  }
}

Future<void> getNewestMsg(String roomID, String msgID, String msgPara) async {
  int _sendID = int.parse(msgID) + 1;
  var url = '${globalString.GlobalString.ipRedis}/getMsg';
  var response = await http.post(Uri.parse(url),
      body: {'RoomID': roomID, 'MsgID': _sendID.toString(), 'MsgPara': msgPara});
  print('Response body in getNewMsg:${response.body}');
  var tagObjsJson = jsonDecode(response.body)['res'] as List;
  List<MessengerPolling> tagObjs =
      tagObjsJson.map((tagJson) => MessengerPolling.fromJson(tagJson)).toList();
  print(tagObjs);

  for (int i =0; i< tagObjs.length; i++){
    var newMsg = tagObjs[i];
    callMethodChannel.checkMessageOrNewRoom(newMsg.roomID, newMsg.sendUserID, newMsg.sendName, newMsg.text, newMsg.msgType, newMsg.msgID);
  }
}

Future<void> setFirstMaxSN(String roomID, String msgSN) async {
  _times++;
  sqlite.updateMsgSN(roomID, msgSN);
  print('進行第一次Client端MaxSN更新');
  if (_times == clientRoomList.length) {
    print('將進行setClientCache');
    sqlite.setClientCache();
    print('Set結果：${await sqlite.chatRoom()}');
  }
}

Future<void> checkRoomNum() async{
  var dataBaseUserInfo = new List();
  dataBaseUserInfo = await sqlite.selectUser();
  var userInfo = dataBaseUserInfo[0];
  var url = '${globalString.GlobalString.ipRedis}/getRoomNum';
  var response = await http.post(Uri.parse(url), body:{
    'UserID':userInfo.userID.toString(),
  });
  Map<String, dynamic> roomNumServer= jsonDecode(response.body);
  print('Server的聊天室數量：${roomNumServer['RoomNum']}');


  String roomNumClient = await sqlite.countChatRoomQuantity();
  print('Client的聊天室數量：$roomNumClient');

  if ((roomNumServer['RoomNum'].toString()) != (roomNumClient.toString())){
    print('聊天室數量不對');

    var roomURL = '${globalString.GlobalString.ipMysql}/getChatRoomList';
    var chatRoom = await http
        .post(Uri.parse(roomURL), body: {'UserName': userInfo.userName.toString(), 'UserID': userInfo.userID.toString()});
    print('Response body:${chatRoom.body}');
    var tagObjsJson = jsonDecode(chatRoom.body)['res'] as List;
    List<ChatUser> tagObjs = tagObjsJson.map((tagJson) => ChatUser.fromJson(tagJson)).toList();
    print(tagObjs);

    var dataBaseRoomList = new List();
    int count = 0;
    dataBaseRoomList = await sqlite.selectRoomList();

    for (var i = 0; i < tagObjs.length; i++){
      for (var j =0; j < dataBaseRoomList.length; j++){
        if (tagObjs[i].roomID.toString() == dataBaseRoomList[j].roomID.toString()){
          count++;
        }
      }
      if (count==0){
        await sqlite.insertSingleRoom(tagObjs[i].roomID.toString(), tagObjs[i].userName.toString(),
            tagObjs[i].userID.toString(), tagObjs[i].userImageUrl.toString(), tagObjs[i].lastMsgTime.toString());
        print('新增聊天室完成');
        var locate = await sqlite.selectLocate();
        var userLocate = locate[0];
        print('${userLocate.place.toString()}');
        if (userLocate.place.toString()=='Index')
          Index.IndexScreenState().refreshChatRoomList();
      }
      count=0;
    }
    updateUserChatRoomNum(userInfo.userID.toString(), tagObjs.length.toString());
  }
}


void updateUserChatRoomNum(String userID, String roomNum) async{
  var url = '${globalString.GlobalString.ipRedis}/setRoomNum';
  var res =
  await http.post(Uri.parse(url), body: {'UserID': userID, 'RoomNum': roomNum});
  print('聊天室新增結果：${res.body}');
}

class RoomMaxSN {
  final String roomID;
  final String maxSN;

  RoomMaxSN(this.roomID, this.maxSN);

  factory RoomMaxSN.fromJson(dynamic json) {
    return RoomMaxSN(json['RoomID'] as String, json['MaxSN'] as String);
  }

  @override
  String toString() {
    if (_times != 0 && _times >= clientRoomList.length) {
      CompareMaxSN().compareMsgSN(roomID, maxSN);
    } else {
      setFirstMaxSN(roomID, maxSN);
    }
    return '{RoomID: $roomID, MaxSN: $maxSN}';
  }
}