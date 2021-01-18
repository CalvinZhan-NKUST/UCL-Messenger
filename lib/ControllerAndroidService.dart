import 'dart:io';
import 'package:flutter/services.dart';

Future<void> runService() async {
  if (Platform.isAndroid) {
    var methodChannel = MethodChannel("com.flutter.service");
    String data = await methodChannel.invokeMethod("startService");
    print("data:$data");
  } else if (Platform.isIOS) {
    print('This is iOS device.');
  }
}

Future<void> stopService() async {
  if (Platform.isAndroid) {
    var methodChannel = MethodChannel("com.flutter.service");
    String data = await methodChannel.invokeMethod("stopService");
    print("data:$data");
  } else if (Platform.isIOS) {
    print('This is iOS device.');
  }
}