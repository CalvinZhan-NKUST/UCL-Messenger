package com.nkust.flutter_msg;

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
import android.os.Build;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

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
    private Timer reconnectTimer = new Timer();
    private Integer count = 0;
    private String roomList = "";
    public static Integer serviceStart = 0;
    private int setClientCount = 0;
    private Map<String, String> clientMsgSN = new HashMap<String, String>();
    private static MqttAndroidClient client;
    private MqttConnectOptions conOpt;

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
            clientID = "User_" + userID;
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
        globalVariable str = new globalVariable();
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
                FormBody.Builder formBody = new FormBody.Builder();
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

    public void mqttInit() {
        Context context = this;
        String uri = host;
        client = new MqttAndroidClient(context, uri, clientID);
        client.setCallback(mqttCallback);
        conOpt = new MqttConnectOptions();
        conOpt.setAutomaticReconnect(true);
        conOpt.setCleanSession(false);
        conOpt.setConnectionTimeout(10);
        conOpt.setKeepAliveInterval(60);
        conOpt.setUserName(userName);
        conOpt.setPassword(passWord.toCharArray());

        boolean doConnect = true;
        String message = "{\"terminal_uid\":\"" + clientID + "\"}";
        String topic = "2";
        Integer qos = 0;
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
                client.subscribe(clientID + "/+", 0);
                Log.d("MQTT", "訂閱Topic:" + clientID + "/+");
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
            Log.d("MQTT", "收到的訊息:" + message.toString());
            String newMessage = new String(message.getPayload());
            JSONObject jsonMQTTObj = new JSONObject(newMessage);
            String sendName = jsonMQTTObj.getString("SendName");
            String content = jsonMQTTObj.getString("Text");
            String roomID = jsonMQTTObj.getString("RoomID");
            String msgID = jsonMQTTObj.getString("MsgID");
            String msgType = jsonMQTTObj.getString("MsgType");
            String userID = jsonMQTTObj.getString("UserID");

            setMessage(roomID, userID, sendName, content, msgType, msgID);
            notification(sendName, content);
            saveClientSN(Integer.parseInt(roomID), Integer.parseInt(msgID));
        }

        @Override
        public void deliveryComplete(IMqttDeliveryToken arg0) {
            Log.d("MQTT", "Delivery Complete:" + arg0);
        }

        @Override
        public void connectionLost(Throwable arg0) {
            Log.d("MQTT", "Connection Lost:" + arg0);
//            client.unregisterResources();
        }
    };

    private void setMessage(String roomID, String userID, String name, String text, String msgType, String msgID) {
        String newMsg = "{" +
                "\"RoomID\":\"" + roomID + "\"," +
                "\"UserID\":\"" + userID + "\"," +
                "\"SendName\":\"" + name + "\"," +
                "\"Text\":\"" + text + "\"," +
                "\"MsgType\":\"" + msgType + "\"," +
                "\"MsgID\":\"" + msgID + "\"" +
                "}";

        Log.d("DemoService", newMsg);
        Bundle message = new Bundle();
        message.putString("NewMessage", newMsg);
        Intent it = new Intent("MessageService");
        it.putExtras(message);
        sendBroadcast(it);
    }


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
            saveClientSN(roomID, serverSN);
            String getSN = String.valueOf(Integer.parseInt(clientMsgSN.get(roomID.toString())) - 1);
            new Thread(new Runnable() {
                @Override
                public void run() {
                    int msgPara = serverSN - Integer.parseInt(clientMsgSN.get(roomID.toString()));
                    getNewMsg(roomID.toString(), getSN, msgPara);
                }
            }).start();
        }
    }

    public void getNewMsg(String roomID, String msgSN, Integer msgPara) {
        globalVariable str = new globalVariable();
        String getIP = str.getIP();

        OkHttpClient getMsgClient = new OkHttpClient().newBuilder().build();
        FormBody formBody = new FormBody.Builder()
                .add("RoomID", roomID)
                .add("MsgID", msgSN)
                .add("MsgPara", msgPara.toString())
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
                        String sendName = jsonObject.getString("SendName");
                        String text = jsonObject.getString("Text");
                        String roomID = jsonObject.getString("RoomID");
                        String msgID = jsonObject.getString("MsgID");
                        String sendUserID = jsonObject.getString("SendUserID");
                        String msgType = jsonObject.getString("MsgType");
                        checkUserAndPlace(roomID, sendUserID, sendName, text);
                        setMessage(roomID, sendUserID, sendName, text, msgType, msgID);
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
        setClientCount = 0;
        if (timer != null) {
            timer.cancel();
            timer = null;
        }
        serviceStart = 0;
        MainActivity.serviceStarted = 0;
        Log.d("Demo", "Service Destroy");
        if (client!=null){
            try {
                client.disconnect();
                client.unregisterResources();
            } catch (MqttException e) {
                e.printStackTrace();
            }
        }
        super.onDestroy();
    }
}
