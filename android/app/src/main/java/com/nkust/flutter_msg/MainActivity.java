package com.nkust.flutter_msg;

import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private Intent serviceIntent;
    private Integer serviceStart = notifyUnit.serviceStart;
    public static Integer serviceStarted = 0;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
//        GeneratedPluginRegistrant.registerWith(getFlutterEngine());

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger()
                , "com.flutter.service")
                .setMethodCallHandler(new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(@NonNull MethodCall methodCall, @NonNull MethodChannel.Result result) {
                        if(methodCall.method.equals("startService")) {
                            if (serviceStart != 1 && serviceStarted != 1){
                                serviceStarted = 1;
                                startService();
                                Log.d("Demo","MainActivity serviceStart:" + serviceStart);
                                Log.d("Demo","Service Started");
                                result.success("Service Started");
                            }else {
                                Log.d("Demo","MainActivity serviceStart:" + serviceStart);
                                Log.d("Demo","Service has been Started");
                                result.success("Service has been Started");
                            }
                        } else if(methodCall.method.equals("stopService")){
                            stopService();
                            Log.d("Demo","ServiceStop");
                            result.success("Service has been Stopped");

                        }
                    }
                });
                }
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