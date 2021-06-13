import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/screens/HomePage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/Model.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

var _roomList = new List();
var _nameList = new List();
var _idList = new List();
var _maxSN = new List();
var _imageList = new List();
var _lastMsgTime = new List();
var _action = new List();

class _LoginState extends State<Login> {
  static const String _channel = 'sendUserID';
  TextEditingController schoolIDController = new TextEditingController();
  TextEditingController passwordController = new TextEditingController();
  int _sendClick = 0;

  @override
  void initState() {
    _sendClick = 0;
    _roomList.clear();
    _nameList.clear();
    _idList.clear();
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
    _sendClick = 0;
    super.dispose();
  }

  Future<void> permissionRequest() async {
    Map<Permission, PermissionStatus> status = await [
      Permission.notification,
      Permission.camera,
      Permission.storage,
      Permission.microphone,
      Permission.mediaLibrary,
      Permission.accessMediaLocation
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    DB.connectDB();
    return WillPopScope(
      child: Scaffold(
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
              child: ElevatedButton(
                child: Text(
                  'Login',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                    primary: Colors.black,
                    onPrimary: Colors.grey,
                    shape: StadiumBorder(side: BorderSide())),
                onPressed: () {
                  if (_sendClick == 0) {
                    _sendClick = 1;
                    _btnClick(schoolIDController.text.trim(),
                        passwordController.text.trim());
                  }
                },
              ),
            ),
            SizedBox(height: 30.0),
          ],
        ),
      ),
      onWillPop: () {
        print('onWillScope');
        SystemNavigator.pop();
        return null;
      },
    );
  }

  _btnClick(String schoolID, String password) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('請稍候...'),
          );
        });
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
        await http.post(Uri.parse(url), body: {'account': schoolID, 'password': password});
    print('Response body:${response.body}');
    res = jsonDecode(response.body);
    print(res['res']);
    if (res['res'] != "登入失敗") {
      userID = (res['res'][0]['UserID']).toString();
      print('UserID:$userID');
      userName = (res['res'][0]['UserName']).toString();
      print('UserName:$userName');
      userImageURL = (res['res'][0]['UserImgURL']).toString();
      print('UserImageURL:$userImageURL');
      token = (res['res'][0]['uuid']).toString();
      print('toke:$token');

      globalString.GlobalString.account = schoolIDController.text.trim();
      globalString.GlobalString.userID = userID;

      var roomURL = '${globalString.GlobalString.ipMysql}/getChatRoomList';
      var chatRoom = await http
          .post(Uri.parse(roomURL), body: {'UserName': userName, 'UserID': userID});
      print('Response body:${chatRoom.body}');
      var tagObjsJson = jsonDecode(chatRoom.body)['res'] as List;
      List<ChatUser> tagObjs =
          tagObjsJson.map((tagJson) => ChatUser.fromJson(tagJson)).toList();

      for (int i =0;i<tagObjs.length;i++){
        _nameList.add(tagObjs[i].userName);
        _roomList.add(tagObjs[i].roomID);
        _idList.add(tagObjs[i].userID);
        _imageList.add(tagObjs[i].userImageUrl);
        _lastMsgTime.add(tagObjs[i].lastMsgTime);
        _action.add('none');
        _maxSN.add('0');
      }

      _sendClick = 0;
      Navigator.of(context).pop();
      showDialog(
          context: context,
          barrierDismissible: false,
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
                      DB.deleteTableData();
                      DB.insertUser(
                          int.parse(userID), userName, userImageURL, token);
                      DB.insertLocate(1, 'Login');
                      DB.insertRoom(_roomList, _maxSN);
                      DB.insertRoomList(
                          _roomList, _nameList, _idList, _imageList, _lastMsgTime, _action);
                      updateUserChatRoomNum(userID);
                      Navigator.of(context).pop();
                      schoolIDController.clear();
                      passwordController.clear();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => HomePage()));
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
          barrierDismissible: false,
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
                TextButton(
                    onPressed: () {
                      _sendClick = 0;
                      Navigator.of(context).pop();
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

void updateUserChatRoomNum(String userID) async {
  String roomNum = _roomList.length.toString();
  var url = '${globalString.GlobalString.ipRedis}/setRoomNum';
  var res = await http.post(Uri.parse(url), body: {'UserID': userID, 'RoomNum': roomNum});
  print('聊天室新增結果：${res.body}');
}
