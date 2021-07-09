import 'dart:async';
import 'package:flutter_msg/screens/HeadShot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_msg/SQLite.dart' as DB;
import 'package:flutter/material.dart';
import 'package:flutter_msg/screens/Login.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;
import 'package:flutter_msg/MethodChannel.dart' as callMethodChannel;
import 'package:flutter_msg/LongPolling.dart' as longPolling;

class PersonalPage extends StatefulWidget {
  @override
  _PersonalPageState createState() => _PersonalPageState();
}

class _PersonalPageState extends State<PersonalPage> {
  TextEditingController newUserNameController = new TextEditingController();
  TextEditingController oldUserPasswordController = new TextEditingController();
  TextEditingController newUserPasswordController = new TextEditingController();
  TextEditingController checkUserPasswordController =
      new TextEditingController();
  Timer _checkFile;


  var dataBaseUserInfo = new List();
  bool image = false;
  var userName = '';
  var userImageUrl = '';
  int userID = 0;
  var token = '';
  String passwordErr = '   ';

  void getUserInfo() async {
    dataBaseUserInfo = await DB.selectUser();
    var userInfo = dataBaseUserInfo[0];
    userID = userInfo.userID;
    userName = userInfo.userName;
    userImageUrl = userInfo.userImageURL;
    token = userInfo.token;
    globalString.GlobalString.userName = userName;
    print('使用者名稱：$userName');
    print('圖片連結：$userImageUrl');
    if (userImageUrl != 'none')
      image = true;
    else
      image = false;
    setState(() {});
  }

  void initState() {
    super.initState();
    getUserInfo();
    checkFile();
  }

  void dispose(){
    if (_checkFile!=null){
      _checkFile.cancel();
      _checkFile = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Container(
        alignment: Alignment.center,
        color: Color(0xfff8f8ff),
        child: Column(
          children: <Widget>[
            SizedBox(height: 150),
            Expanded(
                flex: 2,
                child: Container(
                  height: 200,
                  width: 200,
                  child: Stack(alignment: Alignment.center, children: <Widget>[
                    Container(
                      height: 200,
                      width: 200,
                      child: CircleAvatar(
                        radius: 120,
                        backgroundImage: image
                            ? NetworkImage('$userImageUrl')
                            : AssetImage('assets/005.png'),
                      ),
                    ),
                    Positioned(
                        right: 2,
                        bottom: 0,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                              iconSize: 32,
                              icon: Icon(Icons.camera_alt),
                              onPressed: () {
                                print('更換大頭貼');
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CameraHeadShot()));
                              }),
                        ))
                  ]),
                )),
            Expanded(
                flex: 1,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        '$userName',
                        style: new TextStyle(fontSize: 32),
                      ),
                      IconButton(
                          icon: Icon(Icons.edit),
                          iconSize: 28,
                          onPressed: () {
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('請輸入新的使用者名稱'),
                                    content: new Row(
                                      children: <Widget>[
                                        new Expanded(
                                          child: TextField(
                                            controller: newUserNameController,
                                            autofocus: true,
                                            obscureText: false,
                                            decoration: new InputDecoration(
                                                hintText: '請輸入名稱'),
                                          ),
                                        )
                                      ],
                                    ),
                                    actions: [
                                      CupertinoButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            '取消',
                                            style: TextStyle(fontSize: 18),
                                          )),
                                      CupertinoButton(
                                          onPressed: () async {
                                            if (newUserNameController.text
                                                    .trim() !=
                                                '') {
                                              updateUserInfoServer(userID,
                                                  '${newUserNameController.text.trim()}');
                                              showDialog(
                                                  context: context,
                                                  barrierDismissible: false,
                                                  builder:
                                                      (BuildContext context) {
                                                    return CupertinoAlertDialog(
                                                      title: Text('請稍候...'),
                                                    );
                                                  });
                                              newUserNameController.clear();
                                            }
                                          },
                                          child: Text(
                                            '確認',
                                            style: TextStyle(fontSize: 18),
                                          ))
                                    ],
                                  );
                                });
                          })
                    ])),
            Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            primary: Colors.black,
                            shape: StadiumBorder(side: BorderSide())),
                        child: Text(
                          '更新密碼',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        onPressed: () {
                          print('替換密碼');
                          oldUserPasswordController.clear();
                          newUserPasswordController.clear();
                          checkUserPasswordController.clear();
                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: new Column(
                                    children: <Widget>[
                                      new Expanded(
                                        flex: 1,
                                        child: Text('請輸入舊密碼'),
                                      ),
                                      new Expanded(
                                          flex: 3,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: TextField(
                                              controller:
                                                  oldUserPasswordController,
                                              autofocus: true,
                                              obscureText: true,
                                              decoration: new InputDecoration(
                                                  hintText: '請輸入密碼'),
                                            ),
                                          )),
                                      new Expanded(
                                          flex: 1, child: Text('請輸入新密碼')),
                                      new Expanded(
                                          flex: 3,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: TextField(
                                              controller:
                                                  newUserPasswordController,
                                              autofocus: false,
                                              obscureText: true,
                                              decoration: new InputDecoration(
                                                  hintText: '請輸入密碼'),
                                            ),
                                          )),
                                      new Expanded(
                                          flex: 1, child: Text('請確認新密碼')),
                                      new Expanded(
                                          flex: 3,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: TextField(
                                              controller:
                                                  checkUserPasswordController,
                                              autofocus: false,
                                              obscureText: true,
                                              decoration: new InputDecoration(
                                                  hintText: '請輸入密碼'),
                                            ),
                                          )),
                                    ],
                                  ),
                                  actions: [
                                    CupertinoButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          '取消',
                                          style: TextStyle(fontSize: 18),
                                        )),
                                    CupertinoButton(
                                        onPressed: () {
                                          if (oldUserPasswordController.text.trim() != '' &&
                                              newUserPasswordController.text
                                                      .trim() !=
                                                  '' &&
                                              checkUserPasswordController.text
                                                      .trim() !=
                                                  '') {
                                            checkPassword(
                                                userID,
                                                oldUserPasswordController.text
                                                    .trim(),
                                                newUserPasswordController.text
                                                    .trim(),
                                                checkUserPasswordController.text
                                                    .trim());
                                          } else {
                                            passwordErr = '欄位不能為空白';
                                            showDialog(
                                                context: context,
                                                barrierDismissible: true,
                                                builder:
                                                    (BuildContext context) {
                                                  return CupertinoAlertDialog(
                                                    title: Text('$passwordErr'),
                                                  );
                                                });
                                          }
                                        },
                                        child: Text(
                                          '確認',
                                          style: TextStyle(fontSize: 18),
                                        ))
                                  ],
                                );
                              });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Colors.black,
                              shape: StadiumBorder(side: BorderSide())),
                          child: Text(
                            '登出',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          onPressed: () async {
                            DB.deleteTableData();
//                            DB.dropTable(); //刪除資料表
                            longPolling.shutDownLongPolling();
                            if (io.Platform.isIOS) {
                              var tokenURL =
                                  '${globalString.GlobalString.ipRedis}/saveToken';
                              var saveToken = await http.post(Uri.parse(tokenURL), body: {
                                'UserID': userID.toString(),
                                'Token': 'none',
                                'ChatServerToken':token
                              });
                              print('SaveToken body:${saveToken.body}');
                            }
                            if (io.Platform.isAndroid) {
                              callMethodChannel.stopService();
                            }
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Login()));
                          },
                        ))
                  ],
                ))
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

  updateUserInfoServer(int userID, String userName) async {
    String _updateUserNameUrl =
        '${globalString.GlobalString.ipMysql}/updateUserName';
    var responseChangeResult = await http.post(Uri.parse(_updateUserNameUrl),
        body: {'UserID': userID.toString(), 'UserName': userName, 'Token':token});
    var res = responseChangeResult.body.toString();
    print('更換結果：$res');
    if (res.toString() == 'ok') updateUserInfo(userID, userName);
  }

  updateUserInfo(int userID, String newUserName) {
    DB.updateUserName(userID, newUserName);
    Navigator.of(context).pop();
    Navigator.of(context).pop();
    getUserInfo();
  }

  checkPassword(int userID, String oldPassword, String newPassword,
      String checkPassword) async {
    if (newPassword != checkPassword) {
      print('新密碼：$newPassword');
      print('確認密碼：$checkPassword');
      passwordErr = '新密碼內容不相符';
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text('$passwordErr'),
            );
          });
    } else {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text('請稍候...'),
            );
          });
      updateUserPassword(userID, oldPassword, newPassword);
    }
  }

  updateUserPassword(int userID, String oldPassword, String newPassword) async {
    print('進行密碼修改');
    String _updateUserPasswordUrl =
        '${globalString.GlobalString.ipMysql}/updateUserPassword';
    var responsePasswordResult = await http.post(Uri.parse(_updateUserPasswordUrl), body: {
      'UserID': userID.toString(),
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'Token':token
    });
    var res = responsePasswordResult.body.toString();
    Navigator.of(context).pop();

    if (res != 'Change success!') {
      print('$res');
      passwordErr = '更新失敗，密碼輸入錯誤';
      showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text('$passwordErr'),
            );
          });
    } else {
      print('結果：$res');
      Navigator.of(context).pop();
      passwordErr = '';
    }
  }

  checkFile() {
    _checkFile = new Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (globalString.GlobalString.headShotFilePath != '') {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (BuildContext context) {
              return CupertinoAlertDialog(
                title: Text('請稍候...'),
              );
            });
        uploadFile('Image', globalString.GlobalString.headShotFilePath);
        globalString.GlobalString.headShotFilePath = '';
      }
    });
  }

  uploadFile(String type, String uploadPath) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('${globalString.GlobalString.ipRedis}/uploadFiles'));
    request.fields.addAll({'FileType': '$type','UserID':userID.toString(),'Token':token});
    request.files.add(await http.MultipartFile.fromPath('File', '$uploadPath'));
    http.StreamedResponse response = await request.send();
    String fileUrl = await response.stream.bytesToString();
    print('檔案上傳結果：$fileUrl');
    uploadUserImage(userID.toString(), fileUrl);
  }

  uploadUserImage(String userID, String imageUrl) async {
    String _uploadUserImageUrl =
        '${globalString.GlobalString.ipMysql}/uploadUserImage';
    var responseUploadUserImage = await http.post(Uri.parse(_uploadUserImageUrl), body: {
      'UserID': userID,
      'UserImageUrl': imageUrl,
      'Token': token
    });
    var res = responseUploadUserImage.body.toString();
    print('upload UserImage Result:$res');
    updateUserImageUrl(int.parse(userID), imageUrl);
  }

  updateUserImageUrl(int userID, String userImageUrl) async {
    DB.updateUserImage(userID, userImageUrl);
    getUserInfo();
    Navigator.of(context).pop();
  }
}
