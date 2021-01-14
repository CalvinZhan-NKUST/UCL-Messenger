package com.nkust.flutter_msg;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteOpenHelper;
import android.util.Log;

public class SQLite extends SQLiteOpenHelper {

    private final static int DBVersion = 1;
    private final static String DB_Name = "chatroom";
    private final static String DB_Table = "roomsn";

    public SQLite(Context context) {
        super(context, DB_Name, null, DBVersion);
        Log.d("Demo","連接資料庫");
        // TODO Auto-generated constructor stub
    }


    @Override
    public void onCreate(SQLiteDatabase db) {
        Log.d("Demo","創建資料庫");
        Log.d("Demo","SQLite DBName:" + SQLite.DB_Table);
        String SqlCmd = "CREATE TABLE IF NOT EXISTS roomsn(RoomID INTEGER PRIMARY KEY, MaxSN INTEGER)";
        db.execSQL(SqlCmd);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        Log.d("Demo","更新資料庫");
    }
}
