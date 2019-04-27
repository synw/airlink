import 'package:flutter/material.dart';
import 'package:dataview/dataview.dart';
import 'conf.dart';
import 'intro.dart';
import 'file_explorer.dart';
import 'settings/settings.dart';
import 'settings/data_link/manual.dart';
import 'state.dart';
import 'server/configure.dart';

final routes = {
  '/file_explorer': (BuildContext context) => FileExplorerPage("/"),
  '/settings': (BuildContext context) => SettingsPage(),
  '/server_config': (BuildContext context) => ConfigureServerPage(),
  '/add_data_link_manual': (BuildContext context) => AddDataLinkManual(),
  '/dataview': (BuildContext context) =>
      DataviewPage("/", uploadTo: "http://192.168.1.2:8082/upload")
};

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Airlink',
      home: IntroPage(),
      routes: routes,
      theme: ThemeData.dark(),
    );
  }
}

void main() async {
  initConf();
  state.init();
  runApp(MyApp());
}
