import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/CameraView.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/ChatRoomMsgWidget.dart';
import 'package:flutter_msg/Model.dart';


class ChatScreen extends StatefulWidget {
  ChatScreen(
      {Key key,
      this.userID,
      this.friendName,
      this.userName,
      this.roomID,
      this.friendID,
      this.friendImageUrl,
      this.userImageUrl})
      : super(key: key);
  final String friendID;
  final String friendName;
  final String friendImageUrl;
  final String userName;
  final String userID;
  final String userImageUrl;
  final String roomID;

  @override
  State<ChatScreen> createState() => new ChatScreenState();
}

final List<Widget> _messages = []; // 建立一個空陣列
Map<String, dynamic> res;
Map<String, dynamic> historyMsg;

int _nextSN = 0;
String _mainUserID = '';
String _mainUserName = '';
String _mainUserImageUrl = '';
String _friendID = '';
String _friendName = '';
String _friendImageUrl = '';

String _getHistoryMsgSN = '';
String _recentRoomID = '';
String _textInput = '';
String _msgNew = '${globalString.GlobalString.ipRedis}/getMsg';
String _msgHistory = '${globalString.GlobalString.ipMysql}/getHistoryMsg';
String _uploadFilePath = '';
String _uploadFileType = '';

void setNewMsg(String roomID, String userID, String name, String text,
    String msgType, int msgID) async {
  print('ChatRoom收到新訊息');
  if (_recentRoomID == roomID) {
    print('有傳入新的訊息');
    var chatRoomSN = await DB.specificRoom(roomID);
    var msgSN = chatRoomSN[0].maxSN;
    if (int.parse(msgSN.toString()) < msgID) {
      await DB.updateMsgSN(roomID, msgID.toString());
      ChatScreenState().insertMessageWidget(userID, msgType, name, text, 0);
    }
  }
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = new TextEditingController();
  final ScrollController _scrollController = new ScrollController();
  Timer _checkFile;

  void setLocate(String room) {
    polling.setLocateRoomID(room);
  }

  void checkFile() {
    _checkFile = new Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
      if (_uploadFilePath != '' && _uploadFileType != '') {
        uploadFile(_uploadFileType, _uploadFilePath);
        _uploadFilePath = '';
        _uploadFileType = '';
      }
    });
  }

  void uploadFile(String type, String uploadPath) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('${globalString.GlobalString.ipRedis}/uploadFiles'));
    request.fields.addAll({'FileType': '$type'});
    request.files.add(await http.MultipartFile.fromPath('File', '$uploadPath'));
    http.StreamedResponse response = await request.send();
    String fileUrl = await response.stream.bytesToString();
    print('檔案上傳結果：$fileUrl');
    _submitText(type, fileUrl);
  }

  Future<void> _checkMsg(String msgUrl) async {
    print('checkMsg $_recentRoomID');
    var response = await http.post(Uri.parse(msgUrl), body: {
      'RoomID': _recentRoomID,
      'MsgID': '0',
      'MsgPara': globalString.GlobalString.msgPara
    });
    print('Response body:${response.body}');

    res = jsonDecode(response.body);

    if ((res['res'] != 'none') & (res['res'] != '')) {
      var tagObjsJson = jsonDecode(response.body)['res'] as List;
      List<MessengerChat> tagObjs =
          tagObjsJson.map((tagJson) => MessengerChat.fromJson(tagJson)).toList();
      setMessage(tagObjs);
    }
  }

  void setMessage(List<MessengerChat> setNewMessage) {
    for (int i = (setNewMessage.length - 1); i >= 0; i--) {
      insertMessageWidget(
          setNewMessage[i].sendUserID.toString(),
          setNewMessage[i].msgType,
          setNewMessage[i].sendName,
          setNewMessage[i].text,
          0);
      print('傳入的內容：$i');
    }
    _nextSN = int.parse(setNewMessage[setNewMessage.length - 1].msgID);
    _getHistoryMsgSN =
        (int.parse(setNewMessage[(setNewMessage.length - 1)].msgID) - 1)
            .toString();

    if (_messages.length < 10) {
      print('NewMsgSN:' + _getHistoryMsgSN);
      setHistoryMessage(_getHistoryMsgSN);
    }
  }

  void setHistoryMessage(String msgSN) async {
    _nextSN = int.parse(msgSN) - 10;
    var response = await http.post(Uri.parse(_msgHistory),
        body: {'MsgID': msgSN, 'RoomID': widget.roomID});
    historyMsg = jsonDecode(response.body);
    var hisMsgJson = jsonDecode(response.body)['res'] as List;
    List<MessengerChat> hisObjs =
        hisMsgJson.map((tagJson) => MessengerChat.fromJson(tagJson)).toList();

    print(hisObjs);
    for (int i = (hisObjs.length - 1); i >= 0; i--) {
      int insertPosition = _messages.length;
      insertMessageWidget(hisObjs[i].sendUserID.toString(), hisObjs[i].msgType,
          hisObjs[i].sendName, hisObjs[i].text, insertPosition);
    }

    _getHistoryMsgSN = (int.parse(hisObjs[0].msgID) - 1).toString();
    print('HistoryMsgSN:' + _getHistoryMsgSN);
  }

  void insertMessageWidget(String userID, String messageType, String userName,
      String text, int insertPosition) {
    print('新增訊息');
    if (userID == _mainUserID) {
      switch (messageType) {
        case 'Text':
          _messages.insert(
              insertPosition,
              MessageSend(
                  text: text, send: userName, image: _mainUserImageUrl));
          break;
        case 'text':
          _messages.insert(
              insertPosition,
              MessageSend(
                  text: text, send: userName, image: _mainUserImageUrl));
          break;
        case 'Image':
          _messages.insert(insertPosition,
              ImageSend(text: text, send: userName, image: _mainUserImageUrl));
          break;
        case 'Video':
          _messages.insert(insertPosition,
              VideoSend(text: text, send: userName, image: _mainUserImageUrl));
          break;
      }
    } else {
      switch (messageType) {
        case 'Text':
          _messages.insert(
              insertPosition,
              MessageReceive(
                  text: text, send: userName, image: _friendImageUrl));
          break;
        case 'text':
          _messages.insert(
              insertPosition,
              MessageReceive(
                  text: text, send: userName, image: _friendImageUrl));
          break;
        case 'Image':
          _messages.insert(insertPosition,
              ImageReceive(text: text, send: userName, image: _friendImageUrl));
          break;
        case 'Video':
          _messages.insert(insertPosition,
              VideoReceive(text: text, send: userName, image: _friendImageUrl));
          break;
      }
    }
  }

  void scroller() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _nextSN > 0) {
        print(_scrollController.position.pixels.toString());
        print(_scrollController.position.maxScrollExtent.toString());
        setHistoryMessage(_getHistoryMsgSN);
      }
    });
  }

  Future<void> dispose() async {
    _scrollController.dispose();
    _messages.clear();
    _nextSN = 0;
    _getHistoryMsgSN = '';
    _textInput = '';
    _recentRoomID = '';
    _checkFile.cancel();
    _checkFile = null;
    print('ChatRoom dispose + ${_messages.length}');
    _chatController.dispose();
    DB.updateLocate('none');
    super.dispose();
  }

  void initState() {
    super.initState();
    scroller();
    _mainUserID = widget.userID;
    _mainUserName = widget.userName;
    _mainUserImageUrl = widget.userImageUrl;
    _recentRoomID = widget.roomID;
    _friendID = widget.friendID;
    _friendName = widget.friendName;
    _friendImageUrl = widget.friendImageUrl;
    _messages.clear();
    checkFile();
    _chatController.clear();
    print('ChatRoom init');
    _nextSN = 0;
    _getHistoryMsgSN = '';
    _textInput = '';
    _checkMsg(_msgNew);
    DB.updateLocate(_recentRoomID.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_friendName),
          backgroundColor: Color(0xff4682b4),
        ),
        body: Center(
            child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                padding: new EdgeInsets.all(15.0),
                reverse: true,
                //加入reverse，讓它反轉
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                itemBuilder: (context, index) => _messages[index],
                itemCount: _messages.length,
              ),
            ),
            Container(
                margin: const EdgeInsets.only(bottom: 16.0, left: 4.0),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.photo_camera),
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraView()));
                      },
                    ),
                    Flexible(
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(16.0),
                            border: OutlineInputBorder(),
                            hintMaxLines: 30,
                            hintText: 'Type something...'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _textInput = _chatController.text.trim();
                        if (_textInput.isEmpty == false) {
                          _submitText('Text', _chatController.text.trim());
                        }
                      },
                    ),
                  ],
                )),
            SizedBox(height: 5),
          ],
        )));
  }

  int sendTime = 0;

  Future<void> _submitText(String msgType, String content) async {
    if (sendTime==0)
      insertMessageWidget(_mainUserID, msgType, _mainUserName, content, 0);

    if (msgType == 'Text') _chatController.clear();

    try {
      sendTime++;
      print('執行訊息傳送，時間：${DateTime.now().minute}分${DateTime.now().second}秒');
      Map<String, dynamic> resVersion;
      var url = '${globalString.GlobalString.ipRedis}/send';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields.addAll({
        'RoomID': _recentRoomID,
        'SendUserID': _mainUserID,
        'SendName': _mainUserName,
        'ReceiveName': _friendName,
        'ReceiveUserID': _friendID,
        'Text': '$content',
        'MsgType': '$msgType',
        'DateTime': '${DateTime.now().millisecondsSinceEpoch}'
      });
      http.StreamedResponse response =
          await request.send().timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        resVersion = jsonDecode(await response.stream.bytesToString());
        print('Response body:${resVersion['MsgID']}');
        print(content);
        await DB.updateMsgSN(_recentRoomID, resVersion['MsgID'].toString());
        sendTime = 0;
      } else {
        print(response.statusCode.toString());
        print(response.reasonPhrase);
      }
    } on TimeoutException catch (e) {
      print('timeout error:$e');
      print('重傳開始的時間：${DateTime.now().minute}分${DateTime.now().second}秒\n');
      if (sendTime < 4) _submitText(msgType, content);
    } on SocketException catch (e) {
      print('socket error:$e');
      print('重傳開始的時間：${DateTime.now().minute}分${DateTime.now().second}秒\n');
      if (sendTime < 4) _submitText(msgType, content);
    } finally {
      print('finally');
    }
  }
}

void uploadVideoAndImage(String recordType, String filePath) {
  print('$recordType, $filePath');
  _uploadFileType = recordType;
  _uploadFilePath = filePath;
}
