import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_msg/screens/CameraView.dart';
import 'package:flutter_msg/screens/VideoView.dart';
import 'package:flutter_msg/screens/ImageView.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:video_player/video_player.dart';

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
  _ChatScreenState createState() => _ChatScreenState();
}

final List<Widget> _messages = []; // 建立一個空陣列
Map<String, dynamic> res;
Map<String, dynamic> historyMsg;

int _newMsg = 0;
int _nextSN = 0;

String _getHistoryMsgSN = '';
String _pollingText = '';
String _pollingName = '';
String _reportRoomID = '';
String _textInput = '';
String _msgNew = '${globalString.GlobalString.ipRedis}/getMsg';
String _msgHistory = '${globalString.GlobalString.ipMysql}/getHistoryMsg';
String _uploadFilePath = '';
String _uploadFileType = '';

void setNewMsg(int getMsg, String name, String text) {
  _pollingName = name;
  _pollingText = text;
  _newMsg = getMsg;
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _chatController = new TextEditingController();
  final ScrollController _scrollController = new ScrollController();
  Timer _timerForMsg;
  Timer _checkFile;

  void setLocate(String room) {
    polling.setLocateRoomID(room);
  }

  void getNewMsgFromPolling() {
    var callback = (timer) => {
          if (_newMsg != 0)
            {
              setState(() {
                _messages.insert(
                    0, MessageReceive(text: _pollingText, send: _pollingName, image: widget.friendImageUrl));
                _newMsg = 0;
              })
            }
        };
    _timerForMsg = Timer.periodic(Duration(seconds: 1), callback);
  }

  void checkFile() {
    _checkFile = new Timer.periodic(Duration(seconds: 1), (Timer timer) {
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
    print('checkMsg ${widget.roomID}');
    var response = await http.post(msgUrl, body: {
      'RoomID': widget.roomID,
      'MsgID': '0',
      'MsgPara': globalString.GlobalString.msgPara
    });
    print('Response body:${response.body}');

    res = jsonDecode(response.body);
    if ((res['res'] != 'none') & (res['res'] != '')) {
      var tagObjsJson = jsonDecode(response.body)['res'] as List;
      List<Messenger> tagObjs =
          tagObjsJson.map((tagJson) => Messenger.fromJson(tagJson)).toList();
      setMessage(tagObjs);
    }
  }

  void setMessage(List<Messenger> setNewMessage) {
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
    var response = await http
        .post(_msgHistory, body: {'MsgID': msgSN, 'RoomID': widget.roomID});
    historyMsg = jsonDecode(response.body);
    var hisMsgJson = jsonDecode(response.body)['res'] as List;
    List<Messenger> hisObjs =
        hisMsgJson.map((tagJson) => Messenger.fromJson(tagJson)).toList();

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
    setState(() {
      if (userID == widget.userID) {
        switch (messageType) {
          case 'Text':
            _messages.insert(
                insertPosition,
                MessageSend(
                    text: text, send: userName, image: widget.userImageUrl));
            break;
          case 'text':
            _messages.insert(
                insertPosition,
                MessageSend(
                    text: text, send: userName, image: widget.userImageUrl));
            break;
          case 'Image':
            _messages.insert(
                insertPosition,
                ImageSend(
                    text: text, send: userName, image: widget.userImageUrl));
            break;
          case 'Video':
            _messages.insert(
                insertPosition,
                VideoSend(
                    text: text, send: userName, image: widget.userImageUrl));
            break;
        }
      } else {
        switch (messageType) {
          case 'Text':
            _messages.insert(
                insertPosition,
                MessageReceive(
                    text: text, send: userName, image: widget.friendImageUrl));
            break;
          case 'text':
            _messages.insert(
                insertPosition,
                MessageReceive(
                    text: text, send: userName, image: widget.friendImageUrl));
            break;
          case 'Image':
            _messages.insert(
                insertPosition,
                ImageReceive(
                    text: text, send: userName, image: widget.friendImageUrl));
            break;
          case 'Video':
            _messages.insert(
                insertPosition,
                VideoReceive(
                    text: text, send: userName, image: widget.friendImageUrl));
            break;
        }
      }
    });
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
    setLocate('none');
    _messages.clear();
    _newMsg = 0;
    _nextSN = 0;
    _getHistoryMsgSN = '';
    _pollingText = '';
    _pollingName = '';
    _textInput = '';
    _timerForMsg.cancel();
    _timerForMsg = null;
    _checkFile.cancel();
    _checkFile = null;
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
    checkFile();
    getNewMsgFromPolling();
    _chatController.clear();
    print('ChatRoom init');
    _newMsg = 0;
    _nextSN = 0;
    _getHistoryMsgSN = '';
    _pollingText = '';
    _pollingName = '';
    _textInput = '';
    _checkMsg(_msgNew);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.friendName),
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

  Future<void> _submitText(String msgType, String content) async {
    insertMessageWidget(widget.userID, msgType, widget.userName, content, 0);
    if (msgType == 'Text') _chatController.clear();

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
      'MsgType': '$msgType',
      'DateTime': '${DateTime.now().millisecondsSinceEpoch}'
    });
    print('Response body:${response.body}');
    print(content);
  }
}

void uploadVideoAndImage(String recordType, String filePath) {
  print('$recordType, $filePath');
  _uploadFileType = recordType;
  _uploadFilePath = filePath;
}

class MessageSend extends StatefulWidget {
  final String text;
  final String send;
  final String image;

  MessageSend({Key key, this.text, this.send, this.image}) : super(key: key);

  _MessageSendState createState() => _MessageSendState();
}

class _MessageSendState extends State<MessageSend> {
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.image != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey anchorKey = GlobalKey();
    return GestureDetector(
      onTap: () {
        print('${widget.text}, ${widget.send}');
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
                    sendReport(widget.send, widget.text);
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
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    color: Color(0xff4682b4),
                    padding: EdgeInsets.all(10.0),
                    child: Text(widget.text,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                        style: TextStyle(fontSize: 18.0, color: Colors.white)),
                  )),
            ),
            Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: setImage
                      ? NetworkImage('${widget.image}')
                      : AssetImage('assets/005.png'),
                ),
                Text(widget.send, key: anchorKey)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ImageSend extends StatefulWidget {
  final String text;
  final String send;
  final String image;

  ImageSend({Key key, this.text, this.send, this.image}) : super(key: key);

  _ImageSendState createState() => _ImageSendState();
}

class _ImageSendState extends State<ImageSend> {
  final GlobalKey anchorKey = GlobalKey();
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.image != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImageApp(imageUrl: widget.text)));
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
                    sendReport(widget.send, widget.text);
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
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10.0),
                    bottomLeft: Radius.circular(10.0),
                  ),
                  child: Container(
                      width: 90,
                      height: 160,
                      margin: const EdgeInsets.only(right: 10),
                      color: Color(0xff4682b4),
                      padding: EdgeInsets.all(10.0),
                      child: Image(
                        image: NetworkImage('${widget.text}'),
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ))),
            ),
            Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.image}')
                      : AssetImage('assets/005.png'),
                ),
                Text(widget.send, key: anchorKey)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class VideoSend extends StatefulWidget {
  final String text;
  final String send;
  final String image;

  VideoSend({Key key, this.text, this.send, this.image}) : super(key: key);

  _VideoSendState createState() => _VideoSendState();
}

class _VideoSendState extends State<VideoSend> {
  final GlobalKey anchorKey = GlobalKey();
  VideoPlayerController _controller;

  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.image != 'none')
      setImage = true;
    else
      setImage = false;

    _controller = VideoPlayerController.network('${widget.text}')
      ..initialize().then((_) {
        setState(() {});
      });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VideoApp(videoUrl: widget.text)));
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
                    sendReport(widget.send, widget.text);
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
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10.0),
                    topLeft: Radius.circular(10.0),
                  ),
                  child: Container(
                    height: 160,
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    color: Color(0xff4682b4),
                    padding: EdgeInsets.all(10.0),
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : Container(),
                  )),
            ),
            Column(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.image}')
                      : AssetImage('assets/005.png'),
                ),
                Text(widget.send, key: anchorKey)
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MessageReceive extends StatefulWidget {
  final String text;
  final String send;
  final String image;

  MessageReceive({Key key, this.text, this.send, this.image}) : super(key: key);

  _MessageReceiveState createState() => _MessageReceiveState();
}

class _MessageReceiveState extends State<MessageReceive> {
  final GlobalKey anchorKey = GlobalKey();
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.image != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('${widget.text}, ${widget.send}');
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
                    sendReport(widget.send, widget.text);
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
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.image}')
                      : AssetImage('assets/005.png'),
                ),
                Text(
                  widget.send,
                  key: anchorKey,
                )
              ],
            ),
            Flexible(
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(left: 10),
                    color: Color(0xff00bfff),
                    padding: EdgeInsets.all(10.0),
                    child: Text(widget.text,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 5,
                        style: TextStyle(fontSize: 18.0, color: Colors.white)),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageReceive extends StatefulWidget {
  final String text;
  final String send;
  final String image;

  ImageReceive({Key key, this.text, this.send, this.image}) : super(key: key);

  _ImageReceiveState createState() => _ImageReceiveState();
}

class _ImageReceiveState extends State<ImageReceive> {
  final GlobalKey anchorKey = GlobalKey();
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.image != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImageApp(imageUrl: widget.text)));
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
                    sendReport(widget.send, widget.text);
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
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.image}')
                      : AssetImage('assets/005.png'),
                ),
                Text(
                  widget.send,
                  key: anchorKey,
                )
              ],
            ),
            Flexible(
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                  child: Container(
                      width: 90,
                      height: 160,
                      margin: const EdgeInsets.only(left: 10),
                      color: Color(0xff00bfff),
                      padding: EdgeInsets.all(10.0),
                      child: Image(
                        image: NetworkImage('${widget.text}'),
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.center,
                      ))),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoReceive extends StatefulWidget {
  final String text;
  final String send;
  final String image;

  VideoReceive({Key key, this.text, this.send, this.image}) : super(key: key);

  _VideoReceiveState createState() => _VideoReceiveState();
}

class _VideoReceiveState extends State<VideoReceive> {
  final GlobalKey anchorKey = GlobalKey();
  VideoPlayerController _controller;
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.image != 'none')
      setImage = true;
    else
      setImage = false;

    _controller = VideoPlayerController.network('${widget.text}')
      ..initialize().then((_) {
        setState(() {});
      });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VideoApp(videoUrl: widget.text)));
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
                child: TextButton(
                  child: Text('檢舉這則訊息'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    final scaffold = Scaffold.of(context);
                    scaffold.showSnackBar(SnackBar(
                      content: Text("檢舉訊息即將透過Email傳送"),
                      action: SnackBarAction(
                          label: '確定', onPressed: scaffold.hideCurrentSnackBar),
                    ));
                    sendReport(widget.send, widget.text);
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
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.image}')
                      : AssetImage('assets/005.png'),
                ),
                Text(
                  widget.send,
                  key: anchorKey,
                )
              ],
            ),
            Flexible(
              child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(10.0),
                    topRight: Radius.circular(10.0),
                  ),
                  child: Container(
                    height: 160,
                    width: 90,
                    margin: const EdgeInsets.only(left: 10),
                    color: Color(0xff00bfff),
                    padding: EdgeInsets.all(10.0),
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : Container(),
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class Messenger {
  String msgID;
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
        json['MsgID'].toString() as String,
        json['SendUserID'].toString() as String,
        json['SendName'] as String,
        json['ReceiveName'] as String,
        json['ReceiveUserID'].toString() as String,
        json['MsgType'] as String,
        json['Text'].toString() as String);
  }

  @override
  String toString() {
    return '{ ${this.msgID}, ${this.sendUserID}, ${this.sendName}, '
        '${this.receiveName}, ${this.receiveUserID}, ${this.msgType}, ${this.text} }';
  }
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
