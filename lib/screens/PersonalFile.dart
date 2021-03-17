import 'package:flutter/services.dart';
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/main.dart';
import 'package:flutter_msg/ControllerAndroidService.dart' as serviceAndroid;
import 'package:flutter_msg/LongPolling.dart' as longPolling;

class PersonalPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: MaterialApp(
          routes: {
            "/login": (context) => new MyApp(),
          },
          title: 'UCL Messenger',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primaryColor: Colors.blueAccent,
            accentColor: Color(0xFFFFFFFF),
          ),
          home: Scaffold(
              body:
                  ListView(padding: EdgeInsets.symmetric(horizontal: 50), //水平間距
                      children: <Widget>[
                SizedBox(height: 70),
                Column(children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage: AssetImage('assets/app_icon.png'),
                  )
                ]),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Photo',
                      style: new TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 70),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_box_rounded),
                    SizedBox(width: 10),
                    Text(
                      '${globalString.GlobalString.userName}',
                      style: new TextStyle(fontSize: 22),
                    )
                  ],
                ),
                SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.lock_rounded),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 120,
                    child: RaisedButton(
                      child: Text(
                        '更新密碼',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      color: Colors.black,
                      onPressed: () {
                        final scaffold = Scaffold.of(context);
                        scaffold.showSnackBar(SnackBar(
                          content: Text("功能尚未開放"),
                          action: SnackBarAction(
                              label: '確定',
                              onPressed: scaffold.hideCurrentSnackBar),
                        ));
                      },
                      shape: StadiumBorder(side: BorderSide()),
                    ),
                  )
                ]),
                SizedBox(height: 100),
                RaisedButton(
                  child: Text(
                    '登出',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  color: Colors.black,
                  onPressed: () async {
                    DB.deleteTableData();
                    longPolling.shutDownLongPolling();
                    if (io.Platform.isIOS) {
                      var tokenURL =
                          '${globalString.GlobalString.ipRedis}/saveToken';
                      var saveToken = await http.post(tokenURL, body: {
                        'UserID': globalString.GlobalString.userID,
                        'Token': 'none'
                      });
                      print('SaveToken body:${saveToken.body}');
                    }
                    if (io.Platform.isAndroid) {
                      serviceAndroid.stopService();
                    }
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HomeScreen()));
                  },
                  shape: StadiumBorder(side: BorderSide()),
                )
              ]))),
      onWillPop: () {
        SystemNavigator.pop();
        return null;
      },
    );
  }
}
