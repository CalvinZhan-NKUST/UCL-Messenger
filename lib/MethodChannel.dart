import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_msg/screens/ChatRoom.dart' as chat;
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/Model.dart';

Future<void> runService() async {
  if (Platform.isAndroid) {
    var methodChannel = MethodChannel("com.flutter.service");
    String data = await methodChannel.invokeMethod("startService");
    print("data:$data");
  } else if (Platform.isIOS) {
    print('This is iOS device.');
  }
}

Future<void> stopService() async {
  if (Platform.isAndroid) {
    var methodChannel = MethodChannel("com.flutter.service");
    String data = await methodChannel.invokeMethod("stopService");
    print("data:$data");
  } else if (Platform.isIOS) {
    print('This is iOS device.');
  }
}

void callMethod(){
  var _methodChannel = MethodChannel('com.flutter.getMessage');
  _methodChannel.setMethodCallHandler(methodChannelHandler);
}

Future<String> methodChannelHandler(MethodCall call) async{
  String result = "Flutter收到Android呼叫";
  print("Method = ${call.method}");
  String newMessage = call.arguments.toString();
  print("newMessage:$newMessage");
  updateNewMessage(newMessage);
  return result;
}

void updateNewMessage(String newMsg){
  var msgObjsJson = jsonDecode(newMsg) as List;
  List<NewMessage> msgObjs =
  msgObjsJson.map((msgObjs) => NewMessage.fromJson(msgObjs)).toList();
  print('Decode結果：${msgObjs.toString()}');
  var msgInsert = msgObjs[0];
  print('新增訊息：${msgInsert.roomID}, ${msgInsert.userID}, ${msgInsert.sendName}, ${msgInsert.text}, ${msgInsert.msgType}, ${int.parse(msgInsert.msgID)}');
  checkMessageOrNewRoom(msgInsert.roomID, msgInsert.userID, msgInsert.sendName, msgInsert.text, msgInsert.msgType, int.parse(msgInsert.msgID));
}

void checkMessageOrNewRoom (String roomID, String userID, String name, String text,
    String msgType, int msgID) async {
  var locate = await DB.selectLocate();
  var userLocate = locate[0];

  print('使用者目前位置：${userLocate.place.toString()}');
  print(roomID);
  if (msgType!='NewRoom'){
    if (userLocate.place.toString() != roomID)
      await DB.updateMsgSN(roomID, msgID.toString());
    else
      chat.setNewMsg(roomID, userID, name, text, msgType, msgID);
  }else
    polling.checkRoomNum();

}