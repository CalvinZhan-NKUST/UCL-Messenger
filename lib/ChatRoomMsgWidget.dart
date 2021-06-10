import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_msg/screens/VideoView.dart';
import 'package:flutter_msg/screens/ImageView.dart';
import 'package:video_player/video_player.dart';

class MessageSend extends StatefulWidget {
  final String roomID;
  final String text;
  final String send;
  final String image;

  MessageSend({Key key, this.text, this.send, this.image, this.roomID})
      : super(key: key);

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
                    sendReport(widget.roomID, widget.send, widget.text);
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
  final String roomID;
  final String send;
  final String image;

  ImageSend({Key key, this.text, this.send, this.image, this.roomID})
      : super(key: key);

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
                    sendReport(widget.roomID, widget.send, widget.text);
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

class VideoSend extends StatefulWidget {
  final String text;
  final String roomID;
  final String send;
  final String image;

  VideoSend({Key key, this.text, this.send, this.image, this.roomID})
      : super(key: key);

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
                    sendReport(widget.roomID, widget.send, widget.text);
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

class MessageReceive extends StatefulWidget {
  final String text;
  final String send;
  final String roomID;
  final String image;

  MessageReceive({Key key, this.text, this.send, this.image, this.roomID})
      : super(key: key);

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
                    sendReport(widget.roomID, widget.send, widget.text);
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
                  backgroundImage: setImage
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
  final String roomID;

  ImageReceive({Key key, this.text, this.send, this.image, this.roomID})
      : super(key: key);

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
                    sendReport(widget.roomID, widget.send, widget.text);
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
                  backgroundImage: setImage
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
  final String roomID;
  final String image;

  VideoReceive({Key key, this.text, this.send, this.image, this.roomID})
      : super(key: key);

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
                    sendReport(widget.roomID, widget.send, widget.text);
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
                  backgroundImage: setImage
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

void sendReport(String roomID, String send, String text) async {
  final Email email = Email(
    body: 'RoomID:$roomID, Send:$send, Text:$text',
    subject: 'UCL Messenger Report Email',
    recipients: ['F108118121@nkust.edu.tw'],
    isHTML: false,
  );
  await FlutterEmailSender.send(email);
  print('Email寄出');
}
