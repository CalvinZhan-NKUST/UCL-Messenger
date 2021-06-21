import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/SQLite.dart' as DB;

Future<void> sendMessage(
    String roomID,
    String sendUserID,
    String sendName,
    String receiveName,
    String receiveID,
    String content,
    String msgType,
    String dateTime,
    int msgSN,
    String sendUserToken) async {
  try {
    print('執行訊息傳送，時間：${DateTime.now().minute}分${DateTime.now().second}秒');
    Map<String, dynamic> resMsgSend;
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
      'DateTime': dateTime,
      'Token':sendUserToken
    });
    http.StreamedResponse response =
        await request.send().timeout(Duration(seconds: 10), onTimeout: () {
      throw TimeoutException('Ten seconds timeout.');
    });

    if (response.statusCode == 200) {
      resMsgSend = jsonDecode(await response.stream.bytesToString());
      await DB.updateMsgSN(roomID, resMsgSend['MsgID'].toString());
      await DB.updateRoomListTime(resMsgSend['LastMsgTime'], roomID);
      await DB.updateMsgProcess(int.parse(roomID), msgSN);
      if (msgType == 'Text') {
        var updateMsgSN = new List();
        updateMsgSN.clear();
        updateMsgSN = await DB.selectUpdateMsg(roomID);
        if (updateMsgSN.isNotEmpty) {
          print('傳送下一則待上傳的訊息');
          var sendMsg = updateMsgSN[0];
          print(sendMsg.toString());
          sendMessage(
              sendMsg.roomID.toString(),
              sendMsg.sendUserID.toString(),
              sendMsg.sendName,
              sendMsg.receiveName,
              sendMsg.receiveUserID.toString(),
              sendMsg.text,
              sendMsg.msgType,
              sendMsg.dateTime,
              sendMsg.roomMsgSN,
              sendMsg.sendUserToken);
        }else{
          DB.updateRoomAction('none', roomID);
          print('訊息上傳完畢，更新聊天室狀態');
        }
      }
    } else {
      print('訊息傳送失敗');
      print(response.statusCode.toString());
      print(response.reasonPhrase);
    }
  } on TimeoutException catch (e) {
    print('timeout error:$e');
    print('重傳開始的時間：${DateTime.now().minute}分${DateTime.now().second}秒\n');

    sendMessage(roomID, sendUserID, sendName, receiveName, receiveID, content,
        msgType, dateTime, msgSN, sendUserToken);
  } on SocketException catch (e) {
    print('socket error:$e');
    print('重傳開始的時間：${DateTime.now().minute}分${DateTime.now().second}秒\n');

    sendMessage(roomID, sendUserID, sendName, receiveName, receiveID, content,
        msgType, dateTime, msgSN, sendUserToken);
  } finally {
    print('finally');
  }
}
