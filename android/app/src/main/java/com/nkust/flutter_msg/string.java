package com.nkust.flutter_msg;

import io.flutter.app.FlutterApplication;

import java.util.HashMap;
import java.util.Map;

public class string extends FlutterApplication {
    String ipNotify = "https://chatapp.54ucl.com:4000";
    String roomList = "";
    Map<String, String> roomMsgSN = new HashMap<String, String>();
    Map<String, String> clientMsgSN = new HashMap<String, String>();



    public String getIP(){
        return ipNotify;
    }

    public void setRoomList(String getRoomList) {
        this.roomList = getRoomList;
    }

    public String getRoomList() {
        return roomList;
    }

    public  void setRoomMsgSN(String RoomID, String MsgSN){
        this.roomMsgSN.put(RoomID,MsgSN);
    }

    public String getRoomMsgSN(String RoomID){
        return roomMsgSN.get(RoomID);
    }

    public  void setClientMsgSN(String RoomID, String MsgSN){
        this.clientMsgSN.put(RoomID,MsgSN);
    }

    public String getClientMsgSN(String RoomID){
        return clientMsgSN.get(RoomID);
    }
}
