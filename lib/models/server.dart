import 'package:flutter/foundation.dart';

enum LogMessageClass { success, error, warning }

class ServerLog {
  ServerLog(
      {@required this.requestUrl,
      @required this.message,
      @required this.statusCode,
      @required this.logClass}) {
    time = DateTime.now().toLocal();
  }

  DateTime time;
  String requestUrl;
  final String message;
  final int statusCode;
  final LogMessageClass logClass;

  @override
  String toString() {
    String date = "${time.hour}:${time.minute}:${time.second}";
    String msgClass;
    switch (logClass) {
      case LogMessageClass.success:
        msgClass = "[OK]";
        break;
      case LogMessageClass.warning:
        msgClass = "[WARNING]";
        break;
      case LogMessageClass.error:
        msgClass = "[ERROR]";
        break;
      default:
    }
    if (requestUrl == "") requestUrl = "/";
    String msgHeader = "$requestUrl $statusCode $msgClass";
    String msg = "$msgHeader $date $message";
    return msg;
  }
}
