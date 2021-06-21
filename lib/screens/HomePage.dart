import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter/material.dart';
import 'package:flutter_apns/flutter_apns.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/Model.dart';
import 'package:flutter_msg/screens/BottomNavigation.dart';
import 'package:flutter_msg/screens/Login.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_msg/MethodChannel.dart' as callMethodChannel;


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _token = '';
  var dataBaseUserInfo = new List();
  final connector = createPushConnector();

  Future<void> _register(String userID, String token) async {
    final connector = this.connector;
    connector.configure(
      onLaunch: (data) => onPush('onLaunch', data),
      onResume: (data) => onPush('onResume', data),
      onMessage: (data) => onPush('onMessage', data),
      onBackgroundMessage: _onBackgroundMessage,
    );
    connector.token.addListener(() async {
      _token = connector.token.value.toString();
      print('Token ${connector.token.value}');
      if (io.Platform.isIOS) {
        var tokenURL = '${globalString.GlobalString.ipRedis}/saveToken';
        var saveToken = await http
            .post(Uri.parse(tokenURL), body: {'UserID': userID, 'Token': _token, 'ChatServerToken': token});
        print('SaveToken body:${saveToken.body}');
      }
    });
    connector.requestNotificationPermissions();

    if (connector is ApnsPushConnector) {
      connector.shouldPresent = (x) => Future.value(true);
      connector.setNotificationCategories([
        UNNotificationCategory(
          identifier: 'MEETING_INVITATION',
          actions: [
            UNNotificationAction(
              identifier: 'ACCEPT_ACTION',
              title: 'Accept',
              options: UNNotificationActionOptions.values,
            ),
            UNNotificationAction(
              identifier: 'DECLINE_ACTION',
              title: 'Decline',
              options: [],
            ),
          ],
          intentIdentifiers: [],
          options: UNNotificationCategoryOptions.values,
        ),
      ]);
    }
  }

  Future<dynamic> onPush(String name, Map<String, dynamic> payload) {
    print('========================');

    print('locate:${polling.locateRoomID}');
    print('Name:$name, payload:${payload.toString()}');
    print('aps:${payload['aps']}');
    print('alert:${payload['aps']['alert']}');
    print('title:${payload['aps']['alert']['title']}');
    print('body:${payload['aps']['alert']['body']}');
    print('category:${payload['aps']['category']}');

    convertCategory(payload['aps']['category'].toString(), payload['aps']['alert']['title'].toString(), payload['aps']['alert']['body'].toString());

    print('========================');

    if (name == 'onLaunch') {}
    return Future.value(true);
  }

  void convertCategory(String categoryPayload, String sendName, String sendContent) async{
    Map<String, dynamic> categoryData =jsonDecode(categoryPayload);
    print("執行字串解析");
    print('UserID:${categoryData['UserID']}');
    print('RoomID:${categoryData['RoomID']}');
    print('MsgID:${categoryData['MsgID']}');
    print('MsgID:${categoryData['MsgType']}');
    print("字串解析結束");
    callMethodChannel.checkMessageOrNewRoom(categoryData['RoomID'], categoryData['UserID'], sendName, sendContent, categoryData['MsgType'], int.parse(categoryData['MsgID']));
  }

  Future<dynamic> _onBackgroundMessage(Map<String, dynamic> data) =>
      onPush('onBackgroundMessage', data);

  void getServerVersion() async {
    String _checkUrl = '${globalString.GlobalString.ipMysql}/getVersionCode';
    Map<String, dynamic> resVersion;

    var responseVersion = await http.post(Uri.parse(_checkUrl));
    resVersion = jsonDecode(responseVersion.body);
    print(
        'Server:${resVersion['NowVersion']},Client:${globalString.GlobalString.appVersion}');
    globalString.GlobalString.serverVersion = resVersion['NowVersion'];

    String s = resVersion['NowVersion'].toString();
    String versionCode = '';
    List<String> parts = s.split('.');
    for (int i = 0; i < parts.length; i++) {
      versionCode += parts[i];
    }
    print('$versionCode');
    checkVersion(versionCode);
  }

  void updateAppVersion() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            content: Text(
              '${globalString.GlobalString.versionErr}',
              style: TextStyle(
                  color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () async {
                    if (io.Platform.isIOS) {
                      await launch(globalString.GlobalString.iOSAppUrlLink);
                    } else if (io.Platform.isAndroid) {
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

  void changeMenu() async {
    if (dataBaseUserInfo.isEmpty) {
      navigationToLogin();
      print('進行登入');
    } else {
      var userInfo = dataBaseUserInfo[0];
      print('有資料可以進行持續登入');
      if (io.Platform.isIOS) {
        _register(userInfo.userID.toString(), userInfo.token.toString());
      }
      Map<String, dynamic> res;
      var _url = '${globalString.GlobalString.ipRedis}/keepLogin';
      print(
          'send uuid UserID:${userInfo.userID.toString()}, Token:${userInfo.token}');
      var response = await http.post(Uri.parse(_url),
          body: {'UserID': userInfo.userID.toString(), 'Token': userInfo.token});
      print('Response body:${response.body}');
      res = jsonDecode(response.body);
      print(res['res']);

      print(await DB.selectUpdateData());

      if (res['res'] != 'pass')
        navigationToLogin();
      else
        navigationToIndex();
    }
  }

  void checkVersion(String versionServer) async {
    String s = globalString.GlobalString.appVersion;
    String versionClient = '';
    List<String> parts = s.split('.');
    for (int i = 0; i < parts.length; i++) {
      versionClient += parts[i];
    }
    print('Client:$versionClient, Server:$versionServer');

    if (int.parse(versionClient) >= int.parse(versionServer))
      changeMenu();
    else
      updateAppVersion();
  }

  void navigationToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => Login()));
  }

  void navigationToIndex() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => BottomNavigationController()));
  }

  Future<void> getUserInfo() async {
    dataBaseUserInfo = await DB.selectUser();
  }

  @override
  void initState() {
    getServerVersion();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    DB.connectDB();
    getUserInfo();
    if (Platform.isAndroid)
      callMethodChannel.callMethod();
    return Image.asset('assets/app_icon.png');
  }
}