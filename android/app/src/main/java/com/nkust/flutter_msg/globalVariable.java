package com.nkust.flutter_msg;

import io.flutter.app.FlutterApplication;

import java.util.HashMap;
import java.util.Map;

public class globalVariable extends FlutterApplication {
    String ipNotify = "https://chatapp.54ucl.com:4000";

    public String getIP(){
        return ipNotify;
    }
}
