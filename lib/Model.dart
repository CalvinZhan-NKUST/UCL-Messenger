import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_msg/GlobalVariable.dart' as globalString;

class NewMessage {
  String roomID;
  String userID;
  String sendName;
  String text;
  String msgType;
  String msgID;

  NewMessage(this.sendName, this.roomID, this.userID, this.text, this.msgID,
      this.msgType);

  factory NewMessage.fromJson(dynamic json) {
    return NewMessage(
        json['SendName'] as String,
        json['RoomID'] as String,
        json['UserID'] as String,
        json['Text'] as String,
        json['MsgID'] as String,
        json['MsgType'] as String);
  }

  @override
  String toString() {
    return '{ ${this.sendName}, ${this.roomID}, ${this.userID}, ${this.text}, ${this.msgID}, ${this.msgType} }';
  }
}

class MessengerChat {
  String msgID;
  String sendUserID;
  String msgType;
  String receiveUserID;
  String sendName;
  String text;
  String receiveName;

  MessengerChat(this.msgID, this.sendUserID, this.sendName, this.receiveName,
      this.receiveUserID, this.msgType, this.text);

  factory MessengerChat.fromJson(dynamic json) {
    return MessengerChat(
        json['MsgID'].toString() as String,
        json['SendUserID'].toString() as String,
        json['SendName'] as String,
        json['ReceiveName'] as String,
        json['ReceiveUserID'].toString() as String,
        json['MsgType'] as String,
        json['Text'].toString() as String);
  }

  @override
  String toString() {
    return '{ ${this.msgID}, ${this.sendUserID}, ${this.sendName}, '
        '${this.receiveName}, ${this.receiveUserID}, ${this.msgType}, ${this.text} }';
  }
}

class MessengerPolling {
  int msgID;
  String roomID;
  String sendUserID;
  String msgType;
  String receiveUserID;
  String sendName;
  String text;
  String receiveName;

  MessengerPolling(this.msgID, this.roomID, this.sendUserID, this.sendName,
      this.receiveName, this.receiveUserID, this.msgType, this.text);

  factory MessengerPolling.fromJson(dynamic json) {
    return MessengerPolling(
        int.parse(json['MsgID']) as int,
        json['RoomID'] as String,
        json['SendUserID'] as String,
        json['SendName'] as String,
        json['ReceiveName'] as String,
        json['ReceiveUserID'] as String,
        json['MsgType'] as String,
        json['Text'] as String);
  }

  @override
  String toString() {
    return '{ ${this.roomID}, ${this.msgID}, ${this.sendUserID}, ${this.sendName}, '
        '${this.receiveName}, ${this.receiveUserID}, ${this.msgType}, ${this.text} }';
  }
}

class ReceivedNotification {
  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}

class ChatUser {
  String userName;
  String roomID;
  String userID;
  String userImageUrl;
  String lastMsgTime;

  ChatUser(this.userName, this.roomID, this.userID, this.userImageUrl,
      this.lastMsgTime);

  factory ChatUser.fromJson(dynamic json) {
    return ChatUser(
        json['UserName'] as String,
        json['RoomID'] as String,
        json['UserID'] as String,
        json['UserImageUrl'] as String,
        json['LastMsgTime'] as String);
  }

  @override
  String toString() {
    return '{ ${this.userName}, ${this.roomID}, ${this.userID}, ${this.userImageUrl}, ${this.lastMsgTime} }';
  }
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
      'RoomID': roomID,
      'UserID': userID,
      'UserName': userName,
      'UserImageUrl': userImageUrl
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
    return {'LocateID': locateID, 'Place': place};
  }

  @override
  String toString() {
    return '{LocateID: $locateID, Place: $place}';
  }
}

class FriendResult {
  int userID;
  String userName;
  String account;
  String userImgURL;

  FriendResult(this.userID, this.userName, this.account, this.userImgURL);

  factory FriendResult.fromJson(dynamic json) {
    return FriendResult(json['UserID'] as int, json['UserName'] as String,
        json['Account'] as String, json['UserImgURL'] as String);
  }

  @override
  String toString() {
    return '{ ${this.userID}, ${this.userName}, ${this.account}, ${this.userImgURL}}';
  }
}


