import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/SQLite.dart' as DB;

int sendTime = 0;

Future<void> sendMessage(
    String roomID,
    String sendUserID,
    String sendName,
    String receiveName,
    String receiveID,
    String content,
    String msgType,
    String dateTime) async {
  try {
    sendTime++;
    print('執行訊息傳送，時間：${DateTime.now().minute}分${DateTime.now().second}秒');
    Map<String, dynamic> resVersion;
    var url = '${globalString.GlobalString.ipRedis}/send';
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.fields.addAll({
      'RoomID': roomID,
      'SendUserID': sendUserID,
      'SendName': sendName,
      'ReceiveName': receiveName,
      'ReceiveUserID': receiveID,
      'Text': content,
      'MsgType': msgType,
      'DateTime': dateTime
    });
    http.StreamedResponse response =
        await request.send().timeout(Duration(seconds: 5));
    if (response.statusCode == 200) {
      resVersion = jsonDecode(await response.stream.bytesToString());
      print('Response body:${resVersion['MsgID']}');
      print(content);
      await DB.updateMsgSN(roomID, resVersion['MsgID'].toString());
      sendTime = 0;
    } else {
      print(response.statusCode.toString());
      print(response.reasonPhrase);
    }
  } on TimeoutException catch (e) {
    print('timeout error:$e');
    print('重傳開始的時間：${DateTime.now().minute}分${DateTime.now().second}秒\n');
    if (sendTime < 4)
      sendMessage(roomID, sendUserID, sendName, receiveName, receiveID, content,
          msgType, dateTime);
  } on SocketException catch (e) {
    print('socket error:$e');
    print('重傳開始的時間：${DateTime.now().minute}分${DateTime.now().second}秒\n');
    if (sendTime < 4)
      sendMessage(roomID, sendUserID, sendName, receiveName, receiveID, content,
          msgType, dateTime);
  } finally {
    print('finally');
  }
}
