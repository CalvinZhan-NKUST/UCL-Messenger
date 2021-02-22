import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter/material.dart';
import 'package:flutter_apns/flutter_apns.dart';
import 'package:flutter_msg/screens/Index.dart';
import 'package:flutter_msg/screens/Login.dart';
import 'package:flutter_msg/storage.dart' as apnStorage;
import 'package:http/http.dart' as http;
import 'package:flutter_msg/SQLite.dart' as DB;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class UserInfo{
  static String userID = '';
  static String uuid = '';
}


class _HomePageState extends State<HomePage> {
  Timer _timer;
  int count = 1;
  String _token = '';


  final connector = createPushConnector();

  Future<void> _register() async {
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
            .post(tokenURL, body: {'Token': _token});
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
    apnStorage.storage.append('$name: $payload');
    print('我點了通知欄');
    print('Name:$name, payload:${payload.toString()}');
    final action = UNNotificationAction.getIdentifier(payload);
    print('action:${action.toString()}');
    if (name == 'onLaunch') {}
    return Future.value(true);
  }

  Future<dynamic> _onBackgroundMessage(Map<String, dynamic> data) =>
      onPush('onBackgroundMessage', data);

  changeMenu() async {
    var _duration = new Duration(seconds: 1);
    new Timer(_duration, () {
      _timer = new Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (UserInfo.userID!=null) {
          Map<String, dynamic> res;
          var _url = '${globalString.GlobalString.ipRedis}/keepLogin';
          print('send uuid UserID:${UserInfo.userID}, Token:${UserInfo.uuid}');
          var response = await http.post(
              _url, body: {'UserID': UserInfo.userID, 'uuid': UserInfo.uuid});
          print('Response body:${response.body}');
          res = jsonDecode(response.body);
          print(res['res']);
          if (res['res'] != 'pass') {
            navigationToLogin();
          } else {
            navigationToIndex();
          }
        }else{
          navigationToLogin();
        }
      });
      return _timer;
    });
  }

  void navigationToLogin() {
    _timer.cancel();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HomeScreen()));
  }

  void navigationToIndex() {
    _timer.cancel();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => IndexScreen()));
  }

  @override
  void initState() {
    DB.connectDB();
    if (io.Platform.isIOS) {
      _register();
    }
    print(UserInfo.userID);
    print(UserInfo.uuid);
    changeMenu();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/app_icon.png');
  }
}
