import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/SQLite.dart' as DB;

class ChatScreen extends StatefulWidget {
  ChatScreen(
      {Key key,
      this.userID,
      this.friendName,
      this.userName,
      this.roomID,
      this.friendID})
      : super(key: key);
  final String userID;
  final String friendName;
  final String userName;
  final String roomID;
  final String friendID;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

final List<Widget> _messages = []; // 建立一個空陣列
Map<String, dynamic> res;
var _sendIDList = new List();
var _sendNameList = new List();
var _text = new List();
int _msgMaxSN = 0;
int _paraSN = 0;
int _newMsg = 0;
int _msgStart = 0;

String _pollingText = '';
String _pollingName = '';
String _reportRoomID = '';
String _textInput = '';
String _msgNew = '${globalString.GlobalString.ipRedis}/getMsg';
String _msgHistory = '${globalString.GlobalString.ipMysql}/getHistoryMsg';

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = new TextEditingController();
  final ScrollController _scrollController = new ScrollController();
  Timer _timerForMsg;

  void setLocate(String room) {
    polling.setLocateRoomID(room);
  }

  void getNewMsg() {
    var callback = (timer) => {
          if (_newMsg != 0)
            {
              setState(() {
                _messages.insert(
                    0, MessageReceive(text: _pollingText, send: _pollingName));
                _newMsg = 0;
              })
            }
        };
    _timerForMsg = Timer.periodic(Duration(seconds: 1), callback);
  }

  Future<void> _checkMsg(String msgUrl) async {
    print('checkMsg ${widget.roomID}');
    print('MsgID:$_paraSN');
    var response = await http.post(msgUrl, body: {
      'RoomID': widget.roomID,
      'MsgID': _paraSN.toString(),
      'MsgPara': globalString.GlobalString.msgPara
    });
    print('Response body:${response.body}');

    res = jsonDecode(response.body);
    if ((res['res'] != 'none') & (res['res'] != '')) {
      var tagObjsJson = jsonDecode(response.body)['res'] as List;
      List<Messenger> tagObjs =
          tagObjsJson.map((tagJson) => Messenger.fromJson(tagJson)).toList();
      print(tagObjs);

      int insertLocate = 0;
      if (msgUrl.contains('getMsg')) {
        insertLocate = 0;
        _msgMaxSN = _paraSN;
        print('MaxSN:$_msgMaxSN');
      } else
        insertLocate = _messages.length;

      if (_msgMaxSN == _sendIDList.length -1)
        _msgStart = _sendIDList.length - _paraSN + 1;
      else if (_msgMaxSN < int.parse(globalString.GlobalString.msgPara))
        _msgStart = 0;
      else
        _msgStart = _sendIDList.length - int.parse(globalString.GlobalString.msgPara);


      for (int i = _msgStart; i < _sendIDList.length; i++) {
        setState(() {
          if (_sendIDList[i].toString() == widget.userID) {
            _messages.insert(insertLocate,
                MessageSend(text: _text[i], send: _sendNameList[i]));
          } else {
            _messages.insert(insertLocate,
                MessageReceive(text: _text[i], send: _sendNameList[i]));
          }
        });
      }
      print(_msgStart);
      print(_sendIDList.length);
      _msgStart += 10;
    }
  }

  void scroller() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        print('pixels:${_scrollController.position.pixels}');
        print('max:${_scrollController.position.maxScrollExtent}');
        _paraSN = _paraSN - int.parse(globalString.GlobalString.msgPara);
        if (_paraSN > 0) _checkMsg(_msgHistory);
//        else if(_paraSN<0 && _paraSN!=0){
//          _paraSN+=10;
//          print('sendList Length:${_sendIDList.length}');
//          print('ID:$_paraSN');
//          setState(() {
//            if (_sendIDList[_sendIDList.length-_paraSN].toString() == widget.userID) {
//              _messages.insert(
//                  _messages.length, MessageSend(text: _text[_text.length-_paraSN], send: _sendNameList[_sendNameList.length-_paraSN]));
//            } else {
//              _messages.insert(
//                  _messages.length, MessageReceive(text: _text[_text.length-_paraSN], send: _sendNameList[_sendNameList.length-_paraSN]));
//            }
//          });
//          _paraSN = 0;
//        }
      }
    });
  }

  Future<void> dispose() async {
    _scrollController.dispose();
    setLocate('none');
    _messages.clear();
    _sendIDList.clear();
    _text.clear();
    _sendNameList.clear();
    _msgMaxSN = 0;
    _msgStart = 0;
    _timerForMsg.cancel();
    print('ChatRoom dispose + ${_messages.length}');
    _chatController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    scroller();
    setLocate(widget.roomID);
    _reportRoomID = widget.roomID;
    _messages.clear();
    _sendIDList.clear();
    _text.clear();
    _sendNameList.clear();
    _msgStart = 0;
    _msgMaxSN = 0;
    _paraSN = 0;
    getNewMsg();
    _chatController.clear();
    print('ChatRoom init');
    _checkMsg(_msgNew);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.friendName),
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
                    Flexible(
                      child: TextField(
                        controller: _chatController,
                        decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(16.0),
                            border: OutlineInputBorder(),
                            hintText: 'Type something...'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _textInput = _chatController.text.trim();
                        if (_textInput.isEmpty == false) {
                          _submitText(_chatController.text.trim());
                        }
                      },
                    ),
                  ],
                )),
          ],
        )));
  }

  Future<void> _submitText(String content) async {
    setState(() {
      _messages.insert(0, MessageSend(text: content, send: widget.userName)
//          Container(
//            child: Text(text),
//            alignment: Alignment.centerRight,
//          ));
          );
      _chatController.clear();
    });
    print(widget.roomID);
    print(widget.userID);
    print(widget.userName);
    var url = '${globalString.GlobalString.ipRedis}/send';
    var response = await http.post(url, body: {
      'RoomID': widget.roomID,
      'SendUserID': widget.userID,
      'SendName': widget.userName,
      'ReceiveName': widget.friendName,
      'ReceiveUserID': widget.friendID,
      'Text': '$content',
      'MsgType': 'text',
      'DateTime': '${DateTime.now().millisecondsSinceEpoch}'
    });
    print('Response body:${response.body}');
    print(content);
  }
}

class MessageSend extends StatelessWidget {
  final String text;
  final String send;

  MessageSend({Key key, this.text, this.send}) : super(key: key);
  final GlobalKey anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('$text, $send');
      },
      onLongPressStart: (detail) {
        RenderBox renderBox = anchorKey.currentContext.findRenderObject();
        var offset =
            renderBox.localToGlobal(Offset(0.0, renderBox.size.height));
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(detail.globalPosition.dx, offset.dy,
              detail.globalPosition.dx, offset.dy),
          elevation: 10,
          items: <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
                value: 'value01',
                child: FlatButton(
                  child: Text('檢舉這則訊息'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    final scaffold = Scaffold.of(context);
                    scaffold.showSnackBar(SnackBar(
                      content: Text("檢舉訊息即將透過Email傳送"),
                      action: SnackBarAction(
                          label: '確定', onPressed: scaffold.hideCurrentSnackBar),
                    ));
                    sendReport(send, text);
                  },
                )),
//            PopupMenuDivider(),  //這是分隔線
          ],
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                color: Colors.blueAccent,
                padding: EdgeInsets.all(10.0),
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: TextStyle(fontSize: 18.0, color: Colors.white)),
              ),
            ),
            Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/005.png'),
                ),
                Text(send, key: anchorKey)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessageReceive extends StatelessWidget {
  final String text;
  final String send;

  MessageReceive({Key key, this.text, this.send}) : super(key: key);
  final GlobalKey anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('$text, $send');
      },
      onLongPressStart: (detail) {
        RenderBox renderBox = anchorKey.currentContext.findRenderObject();
        var offset =
            renderBox.localToGlobal(Offset(0.0, renderBox.size.height));
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(detail.globalPosition.dx, offset.dy,
              detail.globalPosition.dx, offset.dy),
          elevation: 10,
          items: <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
                value: 'value01',
                child: FlatButton(
                  child: Text('檢舉這則訊息'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    final scaffold = Scaffold.of(context);
                    scaffold.showSnackBar(SnackBar(
                      content: Text("檢舉訊息即將透過Email傳送"),
                      action: SnackBarAction(
                          label: '確定', onPressed: scaffold.hideCurrentSnackBar),
                    ));
                    sendReport(send, text);
                  },
                )),
//            PopupMenuDivider(),  //這是分隔線
          ],
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/005.png'),
                ),
                Text(
                  send,
                  key: anchorKey,
                )
              ],
            ),
            Flexible(
              child: Container(
                margin: EdgeInsets.only(left: 10),
                color: Colors.red,
                padding: EdgeInsets.all(10.0),
                child: Text(text,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 5,
                    style: TextStyle(fontSize: 18.0, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Messenger {
  int msgID;
  String sendUserID;
  String msgType;
  String receiveUserID;
  String sendName;
  String text;
  String receiveName;

  Messenger(this.msgID, this.sendUserID, this.sendName, this.receiveName,
      this.receiveUserID, this.msgType, this.text);

  factory Messenger.fromJson(dynamic json) {
    return Messenger(
        json['MsgID'] as int,
        json['SendUserID'].toString() as String,
        json['SendName'] as String,
        json['ReceiveName'] as String,
        json['ReceiveUserID'].toString() as String,
        json['MsgType'] as String,
        json['Text'] as String);
  }

  @override
  String toString() {
    _paraSN = msgID;
    _sendIDList.add(sendUserID);
    _sendNameList.add(sendName);
    _text.add(text);
    return '{ ${this.msgID}, ${this.sendUserID}, ${this.sendName}, '
        '${this.receiveName}, ${this.receiveUserID}, ${this.msgType}, ${this.text} }';
  }
}

void setNewMsg(int getMsg, String name, String text) {
  _pollingName = name;
  _pollingText = text;
  _newMsg = getMsg;
}

void sendReport(String send, String text) async {
  final Email email = Email(
    body: 'RoomID:$_reportRoomID, Send:$send, Text:$text',
    subject: 'UCL Messenger Report Email',
    recipients: ['F108118121@nkust.edu.tw'],
    isHTML: false,
  );
  await FlutterEmailSender.send(email);
  print('Email寄出');
}
