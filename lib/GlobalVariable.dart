library flutter_msg.strings;

String ipMysql = 'https://chatapp.54ucl.com:5000';
String ipRedis = 'https://chatapp.54ucl.com:4003';
String eulaTitle = '用戶協議書(EULA)';
String eulaContent = '\n為了社群的環境，營造良好的社交環境，我們將會審查每位使用者的內容；程式中提供舉報功能，被舉報的內容將會被修改。';
String contentErr = '帳號或密碼錯誤\n請重新輸入';
String msgPara = '';
String login = 'none';
String appVersion = '1.1';

void setPara(String str){
  msgPara = str;
}

void setLogin(String str){
  login = str;
}
