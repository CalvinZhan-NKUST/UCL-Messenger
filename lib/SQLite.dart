import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;

//用於避免資料庫過於頻繁的開關
int _notCloseToOften = 0;

//連接資料庫和創建資料表
void connectDB() async {
  final createDatabase = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
    onCreate: (db, version) {
      print('進行資料表user建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS user(UserID INTEGER PRIMARY KEY, Name TEXT);');
      print('進行資料表locate建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS locate(LocateID INTEGER PRIMARY KEY, Place TEXT);');
      print('進行資料表roomsn建置');
      db.execute(
          'CREATE TABLE IF NOT EXISTS roomsn(RoomID INTEGER PRIMARY KEY, MaxSN INTEGER);');
      return;
    },
    version: 1,
  );
  print('Connect Finish');
}

//寫入使用者目前存在的位置
Future<void> insertLocate(int locateID, String place) async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
  );
  final Database db = await database;
  await db.execute('INSERT INTO locate VALUES ($locateID, \'$place\')');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//更新使用者現在處於的畫面
void updateLocate(String place) async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
  );
  final Database db = await database;
  await db.execute('UPDATE locate SET Place=$place WHERE LocatedID=1');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//存入使用者資料
Future<void> insertUser(int userID, String name) async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
  );
  final Database db = await database;
  await db
      .execute('INSERT INTO user (UserID, Name) VALUES ($userID, \'$name\')');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//存入全部的聊天室列表
Future<void> insertRoom(List roomID, List maxSN) async {
  String str = 'VALUES ';
  for (int i = 0; i < roomID.length; i++) {
    str += '(${roomID[i]}, ${maxSN[i]}), ';
  }
  str = str.substring(0, str.length - 2);
  print(str);
  final database = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
  );
  final Database db = await database;
  await db.rawInsert('INSERT INTO roomsn $str');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//刪除資料表全部資料
Future<void> deleteRoom() async {
  _notCloseToOften++;
  final database = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
  );
  final Database db = await database;
  db.execute('DELETE FROM roomsn;');
  db.execute('DELETE FROM locate;');
  db.execute('DELETE FROM user;');
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
    join(await getDatabasesPath(), 'chatroom.db'),
  );
  final Database db = await database;
  db.rawUpdate('UPDATE roomsn SET MaxSN=$msgSN WHERE RoomID=$roomID');
  print('更新所選資訊');
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//查詢資料表
Future<List<ChatRoom>> chatRoom() async {
  final database = openDatabase(
    join(await getDatabasesPath(), 'chatroom.db'),
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
    join(await getDatabasesPath(), 'chatroom.db'),
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
    join(await getDatabasesPath(), 'chatroom.db'),
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
