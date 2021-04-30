package com.nkust.flutter_msg;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private Intent serviceIntent;
    private Integer serviceStart = notifyUnit.serviceStart;
    public static Integer serviceStarted = 0;
    private MethodChannel mMethodChannel;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        GeneratedPluginRegistrant.registerWith(getFlutterEngine());

        mMethodChannel = new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), "com.flutter.getMessage");


        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger()
                , "com.flutter.service")
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {
                        if (methodCall.method.equals("startService")) {
                            if (serviceStart != 1 && serviceStarted != 1) {
                                serviceStarted = 1;
                                startService();
                                Log.d("Demo", "MainActivity serviceStart:" + serviceStart);
                                Log.d("Demo", "Service Started");
                                result.success("Service Started");
                            } else {
                                Log.d("Demo", "MainActivity serviceStart:" + serviceStart);
                                Log.d("Demo", "Service has been Started");
                                result.success("Service has been Started");
                            }
                        } else if (methodCall.method.equals("stopService")) {
                            stopService();
                            Log.d("Demo", "ServiceStop");
                            result.success("Service has been Stopped");

                        }
                    }
                });

        BroadcastReceiver receiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                // 處理 Service 傳來的訊息。
                Bundle message = intent.getExtras();
                String value = message.getString("NewMessage");
                Log.d("DemoService",value);
                callFlutter(value);
            }
        };

        final String Action = "MessageService";
        IntentFilter filter = new IntentFilter(Action);
        registerReceiver(receiver, filter);

    }

    private void callFlutter(String sendMsg) {
        List<String> list = new ArrayList<>();
        list.add(sendMsg);
        mMethodChannel.invokeMethod("com.flutter.getMessage", list, new MethodChannel.Result() {
            @Override
            public void success(@Nullable Object result) { // Flutter 回调过来的结果
                Log.d("DemoService",result.toString());
            }

            @Override
            public void error(String errorCode, @Nullable String errorMessage, @Nullable Object errorDetails) {
                Log.d("DemoService",errorCode+", "+errorMessage+", "+errorDetails);
            }

            @Override
            public void notImplemented() {

            }
        });
    };



    @Override
    protected void onDestroy() {
        Log.d("Demo","Main Destroy");
        super.onDestroy();
    }

    private void stopService(){
        if (serviceIntent==null){
            serviceIntent = new Intent(MainActivity.this, notifyUnit.class);
        }
        stopService(serviceIntent);
        serviceIntent = null;
    }

    private void startService() {
        if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            serviceIntent = new Intent(MainActivity.this, notifyUnit.class);
            startForegroundService(serviceIntent);
            Log.d("Demo","startForegroundService");
        } else {
            serviceIntent = new Intent(MainActivity.this, notifyUnit.class);
            startService(serviceIntent);
            Log.d("Demo","startService");
        }
    }
}