import 'dart:async';
import 'package:airlink/models/server.dart';
import 'package:flutter/material.dart';
import '../state.dart';

class _LogsPageState extends State<LogsPage> {
  List<Widget> items = [];
  StreamSubscription<ServerLog> logSub;

  Widget buildItem(ServerLog logItem) {
    return Padding(
        child: Text("${logItem.toString()}"),
        padding: const EdgeInsets.only(bottom: 10.0));
  }

  @override
  void initState() {
    // initial session log data
    state.fileServer.logs.forEach((logItem) => items.add(buildItem(logItem)));
    // new data coming in
    logSub = state.fileServer.serverLog.listen((logItem) {
      items.add(buildItem(logItem));
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    logSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Server logs")),
      body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(children: <Widget>[
            Expanded(
                child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (BuildContext context, int index) {
                      return items[index];
                    }))
          ])),
    );
  }
}

class LogsPage extends StatefulWidget {
  @override
  _LogsPageState createState() => _LogsPageState();
}
