import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

var _roomList = new List();
var _nameList = new List();
var _idList = new List();
var _maxSN = new List();

class _HomeScreenState extends State<HomeScreen> {
  static const String _channel = 'sendUserID';
  TextEditingController schoolIDController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  static const BasicMessageChannel<String> platform =
      BasicMessageChannel<String>(_channel, StringCodec());
  String _serverVersion = '';
  int _sendClick = 0;


  void checkAppVersion(String version) async{
    String _checkUrl = '${globalString.GlobalString.ipMysql}/getVersionCode';
    Map<String, dynamic> resVersion;

    var responseVersion = await http.post(_checkUrl);
    resVersion = jsonDecode(responseVersion.body);
    print('Server:${resVersion['NowVersion']},Client:$version');
    _serverVersion = resVersion['NowVersion'].toString();
    if (_serverVersion!=version){
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              content: Text(
                '${globalString.GlobalString.versionErr}',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              actions: <Widget>[
                FlatButton(
                    onPressed: () async {
                      if(io.Platform.isIOS){
                        await launch(globalString.GlobalString.iOSAppUrlLink);
                      }else if (io.Platform.isAndroid){
                        await launch(globalString.GlobalString.androidAppUrlLink);
                      }
                    },
                    child: Text(
                      '更新',
                      style: TextStyle(color: Colors.blue, fontSize: 18),
                    )),
              ],
            );
          });
    }
  }

  @override
  void initState() {
    _sendClick = 0;
    _roomList.clear();
    _nameList.clear();
    _idList.clear();
    DB.connectDB();
    permissionRequest();
    super.initState();
  }

  @override
  void dispose() {
    schoolIDController.dispose();
    _roomList.clear();
    _nameList.clear();
    _idList.clear();
    polling.requestPermissions();
    super.dispose();
  }

  Future<void> permissionRequest() async {
    Map<Permission, PermissionStatus> status =
        await [Permission.notification].request();
  }

  @override
  Widget build(BuildContext context) {
    checkAppVersion(globalString.GlobalString.appVersion);
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 22), //水平間距
        children: <Widget>[
          SizedBox(height: 70.0),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Login',
              style: TextStyle(fontSize: 42.0),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 12.0, top: 4.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                color: Colors.black,
                width: 40.0,
                height: 2.0,
              ),
            ),
          ),
          SizedBox(height: 70.0),
          TextField(
            controller: schoolIDController,
            obscureText: false,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: (InputDecoration(
              labelText: '請輸入學號',
            )),
          ),
          SizedBox(height: 30.0),
          TextField(
            controller: passwordController,
            obscureText: true,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: (InputDecoration(
              labelText: '請輸入密碼',
            )),
          ),
          SizedBox(height: 90.0),
          SizedBox(
            height: 45.0,
            width: 270.0,
            child: RaisedButton(
              child: Text(
                'Login',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              color: Colors.black,
              onPressed: () {
                if (_sendClick == 0) {
                  _sendClick = 1;
                  _btnClick(schoolIDController.text.trim(),
                      passwordController.text.trim());
                }
              },
              shape: StadiumBorder(side: BorderSide()),
            ),
          ),
          SizedBox(height: 30.0),
        ],
      ),
    );
  }

  _btnClick(String schoolID, String password) async {
    DB.deleteTableData();
    _roomList.clear();
    _nameList.clear();
    _idList.clear();
    Map<String, dynamic> res;
    var userID = '';
    var userName = '';
    var userImageURL = '';
    var token = '';
    var url = '${globalString.GlobalString.ipMysql}/login';
    print(url);
    var response =
        await http.post(url, body: {'account': schoolID, 'password': password});
    print('Response body:${response.body}');
    res = jsonDecode(response.body);
    print(res['res']);
    if (res['res'] != "登入失敗") {
      userID = (res['res'][0]['UserID']).toString();
      print('UserID:$userID');
      userName = (res['res'][0]['UserName']).toString();
      print('UserName:$userName');
      userImageURL = (res['res'][0]['UserImageURL']).toString();
      print('UserImageURL:$userImageURL');
      token = (res['res'][0]['uuid']).toString();
      print('toke:$token');

//      globalString.GlobalString.setAccount(schoolIDController.text.trim());
      globalString.GlobalString.account = schoolIDController.text.trim();
      DB.insertUser(int.parse(userID), userName, userImageURL, token);
      DB.insertLocate(1, 'Login');

      var roomURL = '${globalString.GlobalString.ipMysql}/getChatRoomList';
      var chatRoom = await http
          .post(roomURL, body: {'UserName': userName, 'UserID': userID});
      print('Response body:${chatRoom.body}');
      var tagObjsJson = jsonDecode(chatRoom.body)['res'] as List;
      List<ChatUser> tagObjs =
          tagObjsJson.map((tagJson) => ChatUser.fromJson(tagJson)).toList();
      print(tagObjs);

      DB.insertRoom(_roomList, _maxSN);
      print('查詢結果：${await DB.chatRoom()}');
      _sendClick = 0;
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              content: Text(
                '${globalString.GlobalString.eulaContent}',
                textAlign: TextAlign.left,
                style: TextStyle(color: Colors.black, fontSize: 18),
              ),
              title: Center(
                  child: Text(
                '${globalString.GlobalString.eulaTitle}',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              )),
              actions: <Widget>[
                CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      schoolIDController.clear();
                      passwordController.clear();
//                      globalString.GlobalString.setUserInfo(_roomList, _nameList, _idList, userID, userName, userImageURL);
                      globalString.GlobalString.userRoomList = _roomList;
                      globalString.GlobalString.userNameList = _nameList;
                      globalString.GlobalString.userIDList = _idList;
                      globalString.GlobalString.userID = userID;
                      globalString.GlobalString.userName = userName;
                      globalString.GlobalString.userImageURL = userImageURL;

                      Navigator.of(context).pushNamedAndRemoveUntil("/index", ModalRoute.withName("/index"));
//                      Navigator.push(context,MaterialPageRoute(builder: (context) => BottomNavigationController()));
//                      Navigator.of(context).pop();
//                      Navigator.push(
//                          context,
//                          MaterialPageRoute(
//                              builder: (context) => IndexScreen(
//                                  userID: userID,
//                                  userName: userName,
//                                  userImageURL: userImageURL,
//                                  roomList: _roomList,
//                                  nameList: _nameList,
//                                  idList: _idList)));
                    },
                    child: Text(
                      '同意',
                      style: TextStyle(fontSize: 18),
                    )),
                CupertinoButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '不同意',
                      style: TextStyle(fontSize: 18),
                    ))
              ],
            );
          });
    } else {
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              content: Text(
                '${globalString.GlobalString.contentErr}',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              actions: <Widget>[
                FlatButton(
                    onPressed: () {
                      _sendClick = 0;
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      '確定',
                      style: TextStyle(color: Colors.blue, fontSize: 18),
                    )),
              ],
            );
          });
    }
  }
}

class ChatUser {
  String userName;
  String roomID;
  String userID;

  ChatUser(this.userName, this.roomID, this.userID);

  factory ChatUser.fromJson(dynamic json) {
    return ChatUser(json['UserName'] as String, json['RoomID'] as String,
        json['UserID'] as String);
  }

  @override
  String toString() {
    _nameList.add(userName);
    _roomList.add(roomID);
    _idList.add(userID);
    _maxSN.add('0');
    return '{ ${this.userName}, ${this.roomID}, ${this.userID} }';
  }
}
