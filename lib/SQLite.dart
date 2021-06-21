import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_msg/LongPolling.dart' as polling;
import 'package:flutter_msg/Model.dart';

//用於避免資料庫過於頻繁的開關
int _notCloseToOften = 0;
String _dataBase = 'chatroom.db';

connectDB() async {
  print('connect DB');
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, _dataBase);
  var ourDb = await openDatabase(path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete);
  return ourDb;
}

//创建数据库表
void _onCreate(Database db, int version) async {
  var batch = db.batch();
  _createTableCompanyV1(batch);
  _updateTableCompanyV1toV2(batch);

  await batch.commit();
  print("Table is created");
}

void _onUpgrade(Database db, int oldVersion, int newVersion) async {
  var batch = db.batch();
  if (oldVersion == 1) {
    _updateTableCompanyV1toV2(batch);
  }
  await batch.commit();
}

//創建DB--初始版本
void _createTableCompanyV1(Batch batch) {
  batch.execute(
    'CREATE TABLE IF NOT EXISTS user(UserID INTEGER PRIMARY KEY, Name TEXT, UserImageURL TEXT, Token TEXT);',
  );
  batch.execute(
    'CREATE TABLE IF NOT EXISTS locate(LocateID INTEGER PRIMARY KEY, Place TEXT);',
  );
  batch.execute(
    'CREATE TABLE IF NOT EXISTS roomsn(RoomID INTEGER PRIMARY KEY, MaxSN INTEGER);',
  );
  batch.execute(
    'CREATE TABLE IF NOT EXISTS roomList(RoomID INTEGER PRIMARY KEY, UserName TEXT, UserID INTEGER);',
  );
}

//更新DB Version: 1->2.
void _updateTableCompanyV1toV2(Batch batch) {
  batch.execute('ALTER TABLE roomList ADD UserImageUrl TEXT');
  batch.execute('ALTER TABLE roomList ADD LastMsgTime TEXT');
  batch.execute('ALTER TABLE roomList ADD Action TEXT');
  batch.execute(
      'CREATE TABLE IF NOT EXISTS msgUpdate(MsgID INTEGER PRIMARY KEY, RoomMsgSN INTEGER, RoomID INTEGER,'
      'SendUserID INTEGER, SendName TEXT, ReceiveName TEXT, ReceiveUserID INTEGER, Text TEXT, MsgType TEXT, DateTime TEXT, UpdateProcess TEXT)');
  batch.execute('ALTER TABLE msgUpdate ADD SendUserToken TEXT');
}

Future<void> insertNewUpdateMsg(
    int roomMsgSN,
    int roomID,
    int sendUserID,
    String sendName,
    String receiveName,
    int receiveUserID,
    String text,
    String msgType,
    String dateTime,
    String updateProcess,
    String sendUserToken) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute(
      'INSERT INTO msgUpdate (RoomMsgSN,RoomID,SendUserID,SendName,ReceiveName,ReceiveUserID,Text,MsgType,DateTime,UpdateProcess,SendUserToken) '
      'VALUES ($roomMsgSN, $roomID, $sendUserID, \'$sendName\', \'$receiveName\', $receiveUserID, \'$text\', \'$msgType\', \'$dateTime\', \'$updateProcess\', \'$sendUserToken\')');
  print('寫入完成：$text');
}

Future<List<MessageUpdate>> selectUpdateData() async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('msgUpdate');
  return List.generate(maps.length, (i) {
    return MessageUpdate(
        roomMsgSN: maps[i]['RoomMsgSN'],
        roomID: maps[i]['RoomID'],
        sendUserID: maps[i]['SendUserID'],
        receiveUserID: maps[i]['ReceiveUserID'],
        sendName: maps[i]['SendName'],
        receiveName: maps[i]['ReceiveName'],
        text: maps[i]['Text'],
        msgType: maps[i]['MsgType'],
        dateTime: maps[i]['DateTime'],
        updateProcess: maps[i]['UpdateProcess'],
        sendUserToken: maps[i]['SendUserToken']);
  });
}

//依照聊天室查詢最新一筆訊息，不管有沒有上傳完成
Future<List<MessageUpdate>> selectUpdateMsgSN(String roomID) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('msgUpdate',where: 'RoomID=$roomID',orderBy: 'RoomMsgSN desc',limit: 1);
  return List.generate(maps.length, (i) {
    return MessageUpdate(
        roomMsgSN: maps[i]['RoomMsgSN'],
        roomID: maps[i]['RoomID'],
        sendUserID: maps[i]['SendUserID'],
        receiveUserID: maps[i]['ReceiveUserID'],
        sendName: maps[i]['SendName'],
        receiveName: maps[i]['ReceiveName'],
        text: maps[i]['Text'],
        msgType: maps[i]['MsgType'],
        dateTime: maps[i]['DateTime'],
        updateProcess: maps[i]['UpdateProcess'],
        sendUserToken: maps[i]['SendUserToken']);
  });
}

//查詢未上傳的訊息
Future<List<MessageUpdate>> selectUpdateMsg(String roomID) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('msgUpdate',where: 'RoomID=$roomID and UpdateProcess=\'unprocessed\'',orderBy: 'RoomMsgSN',limit: 1);
  return List.generate(maps.length, (i) {
    return MessageUpdate(
        roomMsgSN: maps[i]['RoomMsgSN'],
        roomID: maps[i]['RoomID'],
        sendUserID: maps[i]['SendUserID'],
        receiveUserID: maps[i]['ReceiveUserID'],
        sendName: maps[i]['SendName'],
        receiveName: maps[i]['ReceiveName'],
        text: maps[i]['Text'],
        msgType: maps[i]['MsgType'],
        dateTime: maps[i]['DateTime'],
        updateProcess: maps[i]['UpdateProcess'],
        sendUserToken: maps[i]['SendUserToken']);
  });
}

Future<void> updateUpdateMsg(String content, int roomID, int roomMsgSN) async{
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute('UPDATE msgUpdate SET UpdateProcess=\'unprocessed\' and Text=\'$content\' WHERE RoomID=$roomID and RoomMsgSN=$roomMsgSN');
}

Future<void> updateMsgProcess(int roomID, int roomMsgSN) async{
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute('UPDATE msgUpdate SET UpdateProcess=\'success\' WHERE RoomID=$roomID and RoomMsgSN=$roomMsgSN');
}

//寫入使用者目前存在的位置
Future<void> insertLocate(int locateID, String place) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute(
      'INSERT INTO locate (LocateID, Place) VALUES ($locateID, \'$place\')');
}

//更新使用者現在處於的畫面
void updateLocate(String place) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute('UPDATE locate SET Place=\'$place\' WHERE LocateID=1');
}

Future<List<Locate>> selectLocate() async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps = await db.query('locate');
//  await db.close();
  return List.generate(maps.length, (i) {
    return Locate(locateID: maps[i]['Locate'], place: maps[i]['Place']);
  });
}

//存入使用者資料
Future<void> insertUser(
    int userID, String name, String userImgURL, String token) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute(
      'INSERT INTO user (UserID, Name, UserImageURL, Token) VALUES ($userID, \'$name\', \'$userImgURL\', \'$token\')');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//取得使用者資料
Future<List<UserInfo>> selectUser() async {
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
        token: maps[i]['Token']);
  });
}

//更新使用者姓名
Future<void> updateUserName(int userID, String name) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.execute('UPDATE user SET Name=\'$name\' WHERE UserID=$userID');
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
  await db.execute(
      'UPDATE user SET UserImageURL=\'$imageUrl\' WHERE UserID=$userID');
  _notCloseToOften++;
  if (_notCloseToOften == 10) {
    _notCloseToOften = 0;
//    await db.close();
  }
}

//查詢目前聊天室的數量
Future<String> countChatRoomQuantity() async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  int count =
  Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM roomList'));
  return '$count';
}

//存入聊天室清單
Future<void> insertRoomList(List roomID, List userName, List userID,
    List imageList, List lastMsgTime, List action) async {
  String str = 'VALUES ';
  for (int i = 0; i < roomID.length; i++) {
    str +=
        '(${roomID[i]}, \'${userName[i]}\', ${userID[i]}, \'${imageList[i]}\', \'${lastMsgTime[i]}\', \'${action[i]}\'), ';
  }
  str = str.substring(0, str.length - 2);
  print(str);
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawInsert(
      'INSERT INTO roomList (RoomID, UserName, UserID, UserImageUrl, LastMsgTime, Action) $str');
}

//存入單一聊天室
Future<void> insertSingleRoom(String roomID, String userName, String userID,
    String userImageUrl, String lastMsgTime, String action) async {
  print('新增單一個聊天室');
  String insertSingleRoom = 'VALUES ';
  insertSingleRoom +=
      '($roomID, \'$userName\', $userID, \'$userImageUrl\', \'$lastMsgTime\', \'$action\')';
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawInsert(
      'INSERT INTO roomList (RoomID, UserName, UserID, UserImageUrl, LastMsgTime, action) $insertSingleRoom');

  String insertSN = 'VALUES ';
  insertSN += '($roomID, 0)';
  await db.rawInsert('INSERT INTO roomsn (RoomID, MaxSN) $insertSN');
}

Future<void> updateRoomListTime(String dateTime, String roomID) async {
  print('更新聊天室最新時間');
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawQuery(
      'update roomList set LastMsgTime=\'$dateTime\' where RoomID=\'$roomID\'');
}

Future<void> updateRoomAction(String action, String roomID) async {
  print('更新聊天室動作動作');
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  await db.rawQuery(
      'update roomList set Action=\'$action\' where RoomID=\'$roomID\'');
}

//取得聊天室列表
Future<List<RoomList>> selectRoomList() async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps =
      await db.query('roomList', orderBy: 'LastMsgTime desc');
//  await db.close();
  return List.generate(maps.length, (i) {
    return RoomList(
      roomID: maps[i]['RoomID'],
      userID: maps[i]['UserID'],
      userName: maps[i]['UserName'],
      userImageUrl: maps[i]['UserImageUrl'],
      lastMsgTime: maps[i]['LastMsgTime'],
      action: maps[i]['Action']
    );
  });
}

//取得聊天室列表
Future<List<RoomList>> specificRoomAction(String roomID) async {
  final database = openDatabase(
    join(await getDatabasesPath(), _dataBase),
  );
  final Database db = await database;
  final List<Map<String, dynamic>> maps =
  await db.query('roomList', where: '$roomID');
//  await db.close();
  return List.generate(maps.length, (i) {
    return RoomList(
        roomID: maps[i]['RoomID'],
        userID: maps[i]['UserID'],
        userName: maps[i]['UserName'],
        userImageUrl: maps[i]['UserImageUrl'],
        action: maps[i]['Action']
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
