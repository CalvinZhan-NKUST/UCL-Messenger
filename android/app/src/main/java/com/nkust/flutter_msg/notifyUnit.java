package com.nkust.flutter_msg;

import android.app.Application;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.graphics.BitmapFactory;
import android.os.Binder;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Message;
import android.os.Messenger;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import com.google.gson.Gson;

import org.eclipse.paho.android.service.MqttAndroidClient;
import org.eclipse.paho.client.mqttv3.IMqttActionListener;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.IMqttToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.jetbrains.annotations.NotNull;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.MethodChannel;
import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class notifyUnit extends Service {
    private final static String DB_Table = "roomsn";
    private final static String Table_PK = "RoomID";
    private final static String Table_Column = "MaxSN";
    private Context context = this;
    private Timer timer = new Timer();
    private Integer count = 0;
    private String roomList = "";
    public static Integer serviceStart = 0;
    private int setClientCount = 0;
    private Map<String, String> clientMsgSN = new HashMap<String, String>();
    private static MqttAndroidClient client;
    private MqttConnectOptions conOpt;

    //    private String host = "tcp://10.0.2.2:61613";
    private String host = "tcp://chatapp.54ucl.com:1883";
    private String userName = "yoChiMQTT";
    private String passWord = "C217_mia";
    private String clientID = "";


    @Override
    public void onCreate() {
        super.onCreate();

        SQLiteDatabase sqLiteDatabase = openOrCreateDatabase("chatroom.db", MODE_PRIVATE, null);
        Cursor cursor = sqLiteDatabase.rawQuery("SELECT * FROM roomsn", null);
        while (cursor.moveToNext()) {
            int roomID = cursor.getInt(cursor.getColumnIndex("RoomID"));
            int maxSN = cursor.getInt(cursor.getColumnIndex("MaxSN"));
            Log.d("Demo", "Service 查詢結果：" + " RoomID=" + roomID + "MaxSN=" + maxSN);
            roomList += roomID + ",";
        }
        cursor.close();

        SQLiteDatabase sqLiteDataBase = openOrCreateDatabase("chatroom.db", MODE_PRIVATE, null);
        Cursor cursorDB = sqLiteDataBase.rawQuery("SELECT * FROM user", null);
        while (cursorDB.moveToNext()) {
            String userID = cursorDB.getString((cursorDB.getColumnIndex("UserID")));
            clientID = "User_"+userID;
            Log.d("MQTT", "Service 查詢結果：" + " UserID=" + clientID);
        }
        cursorDB.close();


        Log.d("Demo", "onCreate");
        serviceStart = 1;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent intent = new Intent(this, MainActivity.class);
            PendingIntent pendingIntent = PendingIntent.getActivity(this, 11, intent, PendingIntent.FLAG_UPDATE_CURRENT);

            NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            NotificationChannel channel = null;
            channel = new NotificationChannel("messages", "高科大系統", NotificationManager.IMPORTANCE_HIGH);
            notificationManager.createNotificationChannel(channel);

            NotificationCompat.Builder builder =
                    new NotificationCompat.Builder(this, "messages")
                            .setContentText("正在背景執行中")
                            .setContentTitle("UCL Messenger")
                            .setAutoCancel(false)
                            .setCategory(Notification.CATEGORY_SERVICE)
                            .setOngoing(false)
                            .setSmallIcon(R.drawable.nkust)
                            .setLargeIcon(BitmapFactory.decodeResource(getResources(), R.drawable.app_icon))
                            .setContentIntent(pendingIntent);

            startForeground(102, builder.build());
            Log.d("Demo", "serviceStart:" + serviceStart);
        }

        mqttInit();
    }


    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        string str = new string();
        String getIP = str.getIP();
        Log.d("Demo", "onStartCommand");
        Log.d("Demo", "serviceStart:" + serviceStart);
        Log.d("Demo", getIP + "/notify");
        serviceStart = 0;


        timer.schedule(new TimerTask() {
            @Override
            public void run() {
                SQLiteDatabase sqLiteDatabase = openOrCreateDatabase("chatroom.db", MODE_PRIVATE, null);
                Cursor cursor = sqLiteDatabase.rawQuery("SELECT * FROM roomsn", null);
                while (cursor.moveToNext()) {
                    int roomID = cursor.getInt(cursor.getColumnIndex("RoomID"));
                    int maxSN = cursor.getInt(cursor.getColumnIndex("MaxSN"));
                    Log.d("Demo", "onCommand 查詢結果：RoomID=" + roomID + ",MaxSN=" + maxSN);
                }

                sqLiteDatabase.close();
                cursor.close();


                OkHttpClient notifyClient = new OkHttpClient().newBuilder().build();
                FormBody.Builder formBody = new FormBody.Builder();//创建表单请求体
                formBody.add("RoomIDList", roomList);
                Request notifyRequest = new Request.Builder()
                        .url(getIP + "/notify")
                        .post(formBody.build())
                        .build();
                Call notifyCall = notifyClient.newCall(notifyRequest);
                notifyCall.enqueue(new Callback() {
                    @Override
                    public void onFailure(@NotNull Call call, @NotNull IOException e) {
                        Log.d("Demo", "" + e);
                    }

                    @Override
                    public void onResponse(@NotNull Call call, @NotNull Response response) throws IOException {

                        JSONObject appData = null;
                        try {
                            String result = response.body().string();
                            Log.d("Demo", result);
                            appData = new JSONObject(result);
                            JSONArray array = appData.getJSONArray("res");
                            for (int i = 0; i < array.length(); i++) {
                                Log.d("Demo", "開始進行res擷取");
                                JSONObject jsonObject = array.getJSONObject(i);
                                String roomServer = jsonObject.getString("RoomID");
                                String snServer = jsonObject.getString("MaxSN");
                                if (setClientCount == 0) {
                                    saveClientSN(Integer.parseInt(roomServer), Integer.parseInt(snServer));
                                    saveMaxSN(Integer.parseInt(roomServer), Integer.parseInt(snServer));
                                } else {
                                    Log.d("Demo", "res to compare, roomOnServer:" + roomServer + ", snOnServer" + snServer);
                                    compareSN(Integer.parseInt(roomServer), Integer.parseInt(snServer));
                                }
                                Log.d("Demo", "Room:" + roomServer + ", MaxSN:" + snServer);
                            }
                            setClientCount = 1;
                        } catch (JSONException e) {
                            Log.d("Demo", "err:" + e);
                        }
                    }
                });
            }
        }, 0, 60000);

        return super.onStartCommand(intent, flags, startId);
    }

    public void mqttInit(){
        Context context = this;
        String uri = host;
        client = new MqttAndroidClient(context, uri, clientID);
        client.setCallback(mqttCallback);
        conOpt = new MqttConnectOptions();
        conOpt.setCleanSession(true);
        conOpt.setConnectionTimeout(10);
        conOpt.setKeepAliveInterval(30);
        conOpt.setUserName(userName);
        conOpt.setPassword(passWord.toCharArray());

        boolean doConnect = true;
        String message = "{\"terminal_uid\":\"" + clientID + "\"}";
        String topic = "2";
        Integer qos = 1;
        Boolean retained = false;
        if ((!message.equals("")) || (!topic.equals(""))) {
            try {
                conOpt.setWill(topic, message.getBytes(), qos.intValue(), retained.booleanValue());
            } catch (Exception e) {
                Log.d("MQTT", "Exception Occurred", e);
                doConnect = false;
                iMqttActionListener.onFailure(null, e);
            }
        }

        if (doConnect) {
            doClientConnection();
        }
    }

    private void doClientConnection() {
        if (!client.isConnected()) {
            try {
                client.connect(conOpt, null, iMqttActionListener);
            } catch (MqttException e) {
                e.printStackTrace();
            }
        }

    }

    // MQTT是否連接成功
    private IMqttActionListener iMqttActionListener = new IMqttActionListener() {
        @Override
        public void onSuccess(IMqttToken arg0) {
            try {
                client.subscribe(clientID+"/+",0);
            } catch (MqttException e) {
                e.printStackTrace();
            }
            Log.d("MQTT", "連接成功 ");
        }

        @Override
        public void onFailure(IMqttToken arg0, Throwable arg1) {
            arg1.printStackTrace();
        }
    };

    // MQTT接受新訊息
    private MqttCallback mqttCallback = new MqttCallback() {
        @Override
        public void messageArrived(String topic, MqttMessage message) throws Exception {
            String str1 = new String(message.getPayload());
            JSONObject jsonMQTTObj = new JSONObject(str1);
            String sendName = jsonMQTTObj.getString("SendName");
            String content = jsonMQTTObj.getString("Text");
            String roomID = jsonMQTTObj.getString("RoomID");
            String maxSN = jsonMQTTObj.getString("MaxSN");

            notification(sendName,content);
            updateClientSN(Integer.parseInt(roomID),Integer.parseInt(maxSN));
            saveMaxSN(Integer.parseInt(roomID),Integer.parseInt(maxSN));
        }

        @Override
        public void deliveryComplete(IMqttDeliveryToken arg0) {
            Log.d("MQTT","Delivery Complete:"+arg0);
        }

        @Override
        public void connectionLost(Throwable arg0) {
            Log.d("MQTT","Connection Lost:"+arg0);
            mqttInit();
        }
    };


    public void notification(String userName, String text) {
        Context context = this;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent intent = new Intent(context, MainActivity.class);
            PendingIntent pendingIntent = PendingIntent.getActivity(context, 15, intent, PendingIntent.FLAG_CANCEL_CURRENT);

            NotificationManager notificationManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
            NotificationChannel channel = null;
            channel = new NotificationChannel("notification", "高科大推播系統", NotificationManager.IMPORTANCE_HIGH);
            notificationManager.createNotificationChannel(channel);

            channel.canBypassDnd();
            channel.setLockscreenVisibility(Notification.VISIBILITY_SECRET);
            channel.canShowBadge();
            channel.enableVibration(true);

            NotificationCompat.Builder builder =
                    new NotificationCompat.Builder(context, "notification")
                            .setContentTitle(userName)
                            .setContentText(text)
                            .setAutoCancel(true)
                            .setCategory(Notification.CATEGORY_SERVICE)
                            .setOngoing(false)
                            .setSmallIcon(R.drawable.nkust)
                            .setDefaults(NotificationCompat.DEFAULT_VIBRATE)
                            .setLargeIcon(BitmapFactory.decodeResource(context.getResources(), R.drawable.app_icon))
                            .setContentIntent(pendingIntent);


            notificationManager.notify(101, builder.build());

        } else {
            Notification notification;
            NotificationManager manager;
            manager = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
            notification = new Notification.Builder(context)
                    .setContentTitle(userName)
                    .setContentText(text)
                    .setSmallIcon(R.drawable.app_icon)
                    .setWhen(System.currentTimeMillis())
                    .build();
            manager.notify(0, notification);
        }
    }

    public void saveMaxSN(Integer roomID, Integer msgSN) {
        SQLiteDatabase sqLiteDatabase = openOrCreateDatabase("chatroom.db", MODE_PRIVATE, null);
        ContentValues cv = new ContentValues();
        cv.put("MaxSN", msgSN);
        String whereClause = "RoomID=" + roomID.toString();
        sqLiteDatabase.update("roomsn", cv, whereClause, null);
        sqLiteDatabase.close();
        cv.clear();
    }

    public void saveClientSN(Integer roomID, Integer msgSN) {
        clientMsgSN.put(roomID.toString(), msgSN.toString());
    }

    public void updateClientSN(Integer roomID, Integer msgSN) {
        clientMsgSN.put(roomID.toString(), msgSN.toString());
        //更新進資料庫
    }

    public void checkUserAndPlace(String roomID, String sendUserID, String title, String content) {
        int userID = 0;
        String userLocate = "";

        SQLiteDatabase sqLiteDatabase = openOrCreateDatabase("chatroom.db", MODE_PRIVATE, null);

        Cursor cursorUser = sqLiteDatabase.rawQuery("SELECT * FROM user", null);
        while (cursorUser.moveToNext()) {
            userID = cursorUser.getInt(cursorUser.getColumnIndex("UserID"));
            Log.d("Demo", "onCommand 查詢結果：UserID=" + userID);
        }

        Cursor cursorLocate = sqLiteDatabase.rawQuery("SELECT * FROM locate", null);
        while (cursorLocate.moveToNext()) {
            userLocate = cursorLocate.getString(cursorLocate.getColumnIndex("Place"));
            Log.d("Demo", "onCommand 查詢結果：UserID=" + userID);
        }

        if (userID != Integer.parseInt(sendUserID) && (roomID.equals(userLocate) == false)) {
            notification(title, content);
        }

        sqLiteDatabase.close();
        cursorUser.close();
        cursorLocate.close();
    }

    public void compareSN(Integer roomID, Integer serverSN) {
        Log.d("Demo", "Compare roomID:" + roomID + ",serverSN:" + serverSN);
        if (Integer.parseInt(clientMsgSN.get(roomID.toString())) < serverSN) {
            String getSN = String.valueOf(serverSN - 1);
            new Thread(new Runnable() {
                @Override
                public void run() {
                    getNewMsg(roomID.toString(), getSN);
                }
            }).start();
        }
    }

    public void getNewMsg(String roomID, String msgSN) {
        string str = new string();
        String getIP = str.getIP();

        OkHttpClient getMsgClient = new OkHttpClient().newBuilder().build();
        FormBody formBody = new FormBody.Builder()
                .add("RoomID", roomID)
                .add("MsgID", msgSN)
                .add("MsgPara", "1")
                .build();

        Request getMsgRequest = new Request.Builder()
                .url(getIP + "/getMsg")
                .post(formBody)
                .build();
        Call getMsgCall = getMsgClient.newCall(getMsgRequest);
        getMsgCall.enqueue(new Callback() {
            @Override
            public void onFailure(@NotNull Call call, @NotNull IOException e) {
                Log.d("Demo", "" + e);
            }

            @Override
            public void onResponse(@NotNull Call call, @NotNull Response response) throws IOException {
                JSONObject object = null;
                String result = response.body().string();
                Log.d("Demo", result);
                try {
                    object = new JSONObject(result);
                    JSONArray array = object.getJSONArray("res");
                    for (int i = 0; i < array.length(); i++) {
                        JSONObject jsonObject = array.getJSONObject(i);
                        String title = jsonObject.getString("SendName");
                        String content = jsonObject.getString("Text");
                        String roomID = jsonObject.getString("RoomID");
                        String msgID = jsonObject.getString("MsgID");
                        String sendUSerID = jsonObject.getString("SendUserID");
                        updateClientSN(Integer.parseInt(roomID), Integer.parseInt(msgID));
                        checkUserAndPlace(roomID, sendUSerID, title, content);
                    }
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
        });

    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        Log.d("Demo", "onBind");
        return null;
    }

    @Override
    public void onDestroy() {
        if (timer != null){
            timer.cancel();
            timer = null;
        }
        serviceStart = 0;
        MainActivity.serviceStarted = 0;
        Log.d("Demo", "Service Destroy");
//        stopSelf();
        try {
//            client.disconnect();
            client.unregisterResources();
            client.close();
        } catch (MqttException e) {
            e.printStackTrace();
        }
        super.onDestroy();
    }
}
