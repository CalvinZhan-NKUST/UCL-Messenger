import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/SQLite.dart' as sqlite;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:flutter_msg/screens/ChatRoom.dart' as chat;
import 'package:vibration/vibration.dart';

var period = const Duration(seconds: 5);
bool timeStart = false;
var clientRoomList = new List();
int _times = 0;
Timer _pollingTimer;
Map<String, String> client = {};
String _userID = '';
String locateRoomID = '';
String _notifyRoomID = '';

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
      var url = '${globalString.GlobalString.ipRedis}/notify';
      var response = await http.post(url, body: {'RoomIDList': roomNotify});
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
      getNewestMsg(roomID, client[roomID]);
      sqlite.updateMsgSN(roomID, (int.parse(client[roomID]) + 1).toString());
      sqlite.setClientCache();
      print('進行取得最新訊息，並且需要通知！！！');
    }
  }
}

Future<void> getNewestMsg(String roomID, String msgID) async {
  int _sendID = int.parse(msgID) + 1;
  _notifyRoomID = roomID;
  var url = '${globalString.GlobalString.ipRedis}/getMsg';
  var response = await http.post(url,
      body: {'RoomID': roomID, 'MsgID': _sendID.toString(), 'MsgPara': '1'});
  print('Response body in getNewMsg:${response.body}');
  var tagObjsJson = jsonDecode(response.body)['res'] as List;
  List<Messenger> tagObjs =
      tagObjsJson.map((tagJson) => Messenger.fromJson(tagJson)).toList();
  print(tagObjs);
// Then do notification.
}

Future<void> notification(
    String sendName, String sendUserID, String text) async {
  print('notify senderUser:$sendUserID,UserID:$_userID');

  print('notifyRoomID:$_notifyRoomID,chatRoomID:$locateRoomID');
  if (_notifyRoomID != locateRoomID) {
    Vibration.vibrate();
//      以下為前景通知
//      print('sendUserID:$sendUserID,UserID:$_userID');
//      print('正在進行推播通知');
//
//      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
//          onSelectNotification: (String payload) async {
//            if (payload != null) {
//              debugPrint('notification payload: $payload');
//            }
//          });
//
//      const AndroidNotificationDetails androidPlatformChannelSpecifics =
//      AndroidNotificationDetails(
//          'your channel id', 'your channel name', 'your channel description',
//          importance: Importance.max,
//          priority: Priority.high,
//          ticker: 'ticker');
//      const IOSNotificationDetails iosNotificationDetails =
//      IOSNotificationDetails();
//      const NotificationDetails platformChannelSpecifics = NotificationDetails(
//          android: androidPlatformChannelSpecifics,
//          iOS: iosNotificationDetails);
//      await flutterLocalNotificationsPlugin
//          .show(0, sendName, text, platformChannelSpecifics, payload: 'item x');
  } else {
    chat.setNewMsg(1, sendName, text);
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

class Messenger {
  int msgID;
  String roomID;
  String sendUserID;
  String msgType;
  String receiveUserID;
  String sendName;
  String text;
  String receiveName;

  Messenger(this.msgID, this.roomID, this.sendUserID, this.sendName,
      this.receiveName, this.receiveUserID, this.msgType, this.text);

  factory Messenger.fromJson(dynamic json) {
    return Messenger(
        int.parse(json['MsgID']) as int,
        json['RoomID'] as String,
        json['SendUserID'] as String,
        json['SendName'] as String,
        json['ReceiveName'] as String,
        json['ReceiveUserID'] as String,
        json['MsgType'] as String,
        json['Text'] as String);
  }

  @override
  String toString() {
    notification(sendName, sendUserID, text);
    return '{ ${this.roomID}, ${this.msgID}, ${this.sendUserID}, ${this.sendName}, '
        '${this.receiveName}, ${this.receiveUserID}, ${this.msgType}, ${this.text} }';
  }
}

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}
