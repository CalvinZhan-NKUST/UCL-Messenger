import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/ChatRoom.dart';

class RecentChat extends StatefulWidget {
  final String friendName;
  final String userID;
  final String userName;
  final String userImageUrl;
  final String roomID;
  final String friendID;
  final String friendImageUrl;
  final String token;

  RecentChat({Key key,
    this.friendName,
    this.userID,
    this.userName,
    this.userImageUrl,
    this.roomID,
    this.friendID,
    this.friendImageUrl,
    this.token})
      : super(key: key);

  _RecentChatState createState() => _RecentChatState();

}

class _RecentChatState extends State<RecentChat>{
  bool setImage = false;

  void initState() {
    super.initState();
    if (widget.friendImageUrl != 'none')
      setImage = true;
    else
      setImage = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('click $widget.roomID');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatScreen(
                  friendName: widget.friendName,
                  userID: widget.userID,
                  userName: widget.userName,
                  roomID: widget.roomID,
                  friendID: widget.friendID,
                  userImageUrl: widget.userImageUrl,
                  friendImageUrl: widget.friendImageUrl,
                  token: widget.token,
                )));
      },
      child: Container(
        margin: EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomRight: Radius.circular(10.0),
            topRight: Radius.circular(10.0),
            topLeft: Radius.circular(10.0),
            bottomLeft: Radius.circular(10.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.45,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.blue, Colors.grey]
                )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Text(''),
                ),
                CircleAvatar(
                  radius: 25,
                  backgroundImage:  setImage
                      ? NetworkImage('${widget.friendImageUrl}')
                      : AssetImage('assets/005.png'),
                ),
                SizedBox(width: 10),
                Container(
                  child: Text(widget.friendName,
                      style: TextStyle(
                          fontSize: 28.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none)),
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.centerRight,
                    child: Text('',
                        style: TextStyle(
                            fontSize: 24.0,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
