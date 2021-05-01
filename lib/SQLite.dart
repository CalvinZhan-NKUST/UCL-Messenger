import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/GlobalVariable.dart' as globalString;

//用於避免資料庫過於頻繁的開關
int _notCloseToOften = 0;
String _dataBase = 'chatroom.db';

//連接資料庫和創建資料表
void connectDB() async {
  final createDatabase = openDatabase(
    join(await getDatabasesPath(), _dataBase),
    onCreate: (db, version) {
      print('進行資料表user建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS user(UserID INTEGER PRIMARY KEY, Name TEXT, UserImageURL TEXT, Token TEXT);');
      print('進行資料表locate建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS locate(LocateID INTEGER PRIMARY KEY, Place TEXT);');
      print('進行資料表roomsn建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS roomsn(RoomID INTEGER PRIMARY KEY, MaxSN INTEGER);');
      print('進行資料表roomList建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS roomList(RoomID INTEGER PRIMARY KEY, UserName TEXT, UserID INTEGER, UserImageUrl TEXT);');
      return;
    },
//    onUpgrade: _upgradeDataBase,
    version: 2,
  );
  print('Connect Finish');
}

Future<String> countChatRoomQuantity() async{
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  int count = Sqflite
      .firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM roomList'));
  return '$count';
}

//寫入使用者目前存在的位置
Future<void> insertLocate(int locateID, String place) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute('INSERT INTO locate (LocateID, Place) VALUES ($locateID, \'$place\')');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//更新使用者現在處於的畫面
void updateLocate(String place) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute('UPDATE locate SET Place=\'$place\' WHERE LocateID=1');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

Future<List<Locate>> selectLocate() async{
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('locate');
//  await db.close();
  return List.generate(maps.length, (i) {
    return Locate(
        locateID: maps[i]['Locate'],
        place: maps[i]['Place']
    );
  });
}

//存入使用者資料
Future<void> insertUser(int userID, String name, String userImgURL, String token) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db
      .execute('INSERT INTO user (UserID, Name, UserImageURL, Token) VALUES ($userID, \'$name\', \'$userImgURL\', \'$token\')');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//取得使用者資料
Future<List<UserInfo>> selectUser() async{
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('user');
//  await db.close();
  return List.generate(maps.length, (i) {
    return UserInfo(
      userID: maps[i]['UserID'],
      userName: maps[i]['Name'],
      userImageURL: maps[i]['UserImageURL'],
      token: maps[i]['Token']
    );
  });
}

//更新使用者姓名
Future<void> updateUserName(int userID, String name) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db
      .execute('UPDATE user SET Name=\'$name\' WHERE UserID=$userID');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//更新使用者照片
Future<void> updateUserImage(int userID, String imageUrl) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db
      .execute('UPDATE user SET UserImageURL=\'$imageUrl\' WHERE UserID=$userID');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//存入聊天室清單
Future<void> insertRoomList(List roomID, List userName, List userID, List imageList) async{
  String str = 'VALUES ';
  for (int i = 0; i < roomID.length; i++) {
    str += '(${roomID[i]}, \'${userName[i]}\', ${userID[i]}, \'${imageList[i]}\'), ';
  }
  str = str.substring(0, str.length - 2);
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawInsert('INSERT INTO roomList (RoomID, UserName, UserID, UserImageUrl) $str');
}

//存入單一聊天室
Future<void> insertSingleRoom(String roomID, String userName, String userID, String userImageUrl) async{
  print('新增單一個聊天室');
  String insertSingleRoom = 'VALUES ';
  insertSingleRoom += '($roomID, \'$userName\', $userID, \'$userImageUrl\')';
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawInsert('INSERT INTO roomList (RoomID, UserName, UserID, UserImageUrl) $insertSingleRoom');

  String insertSN = 'VALUES ';
  insertSN +='($roomID, 0)';
  await db.rawInsert('INSERT INTO roomsn (RoomID, MaxSN) $insertSN');
}

//取得聊天室列表
Future<List<RoomList>> selectRoomList() async{
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('roomList');
//  await db.close();
  return List.generate(maps.length, (i) {
    return RoomList(
      roomID: maps[i]['RoomID'],
      userID: maps[i]['UserID'],
      userName: maps[i]['UserName'],
      userImageUrl: maps[i]['UserImageUrl'],
    );
  });
}

//存入全部的聊天室列表和預設的編號
Future<void> insertRoom(List roomID, List maxSN) async {
  String str = 'VALUES ';
  for (int i = 0; i < roomID.length; i++) {
    str += '(${roomID[i]}, ${maxSN[i]}), ';
  }
  str = str.substring(0, str.length - 2);
  print(str);
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawInsert('INSERT INTO roomsn $str');
}

//刪除資料表全部資料
Future<void> deleteTableData() async {
  _notCloseToOften++;
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  db.execute('DELETE FROM roomsn;');
  db.execute('DELETE FROM locate;');
  db.execute('DELETE FROM user;');
  db.execute('DELETE FROM roomList;');
  print('刪除資料表資料');
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

Future<void> dropTable() async {
  _notCloseToOften++;
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  db.execute('DROP TABLE roomsn;');
  db.execute('DROP TABLE locate;');
  db.execute('DROP TABLE user;');
  db.execute('DROP TABLE roomList;');
  print('刪除資料表資料');
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//更新目前最大訊息編號
Future<void> updateMsgSN(String roomID, String msgSN) async {
  _notCloseToOften++;
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  db.rawUpdate('UPDATE roomsn SET MaxSN=$msgSN WHERE RoomID=$roomID');
}

//查詢聊天室編號
Future<List<ChatRoom>> chatRoom() async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('roomsn');
//  await db.close();
  return List.generate(maps.length, (i) {
    return ChatRoom(
      roomID: maps[i]['RoomID'],
      maxSN: maps[i]['MaxSN'],
    );
  });
}

//設定前端訊息編號
Future<List<ChatRoom>> setClientCache() async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('roomsn');
  return List.generate(maps.length, (i) {
    polling.CompareMaxSN()
        .setClientSN(maps[i]['RoomID'].toString(), maps[i]['MaxSN'].toString());
    return ChatRoom(
      roomID: maps[i]['RoomID'],
      maxSN: maps[i]['MaxSN'],
    );
  });
}

//查詢單一房間的MaxSN
Future<List<ChatRoom>> specificRoom(String roomID) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;

  final List<Map<String, dynamic>> maps =
      await db.rawQuery('SELECT * FROM roomsn where RoomID=$roomID');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
  return List.generate(maps.length, (i) {
    return ChatRoom(
      roomID: maps[i]['RoomID'],
      maxSN: maps[i]['MaxSN'],
    );
  });
}

class ChatRoom {
  final int roomID;
  final int maxSN;

  ChatRoom({this.roomID, this.maxSN});

  Map<String, dynamic> toMap() {
    return {
      'RoomID': roomID,
      'MaxSN': maxSN,
    };
  }

  @override
  String toString() {
    return '{RoomID: $roomID, MaxSN: $maxSN}';
  }
}

class UserInfo {
  final int userID;
  final String userName;
  final String userImageURL;
  final String token;

  UserInfo({this.userID, this.userName, this.userImageURL, this.token});

  Map<String, dynamic> toMap() {
    return {
      'UserID': userID,
      'UserName': userName,
      'UserImageURL': userImageURL,
      'Token': token
    };
  }

  @override
  String toString() {
    globalString.GlobalString.userID = userID.toString();
    globalString.GlobalString.uuid = token;
    globalString.GlobalString.userImageURL = userImageURL;
    globalString.GlobalString.userName = userName;
    return '{UserID: $userID, UserName: $userName, UserImageURL: $userImageURL, Token: $token}';
  }
}

class RoomList {
  final int roomID;
  final String userName;
  final int userID;
  final String userImageUrl;

  RoomList({this.roomID, this.userName, this.userID, this.userImageUrl});

  Map<String, dynamic> toMap() {
    return {
      'RoomID':roomID,
      'UserID': userID,
      'UserName': userName,
      'UserImageUrl':userImageUrl
    };
  }

  @override
  String toString() {
    return '{RoomID: $roomID, UserID: $userID, UserName: $userName, UserImageUrl: $userImageUrl}';
  }
}

class Locate {
  final int locateID;
  final String place;

  Locate({this.locateID, this.place});

  Map<String, dynamic> toMap() {
    return {
      'LocateID':locateID,
      'Place': place
    };
  }

  @override
  String toString() {
    return '{LocateID: $locateID, Place: $place}';
  }
}
