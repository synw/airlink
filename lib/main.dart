import 'package:flutter/material.dart';
import 'package:err/err.dart';
import 'conf.dart';
import 'intro.dart';
import 'file_explorer_page.dart';
import 'settings/settings.dart';
import 'settings/data_link/manual.dart';
import 'state.dart';
import 'server/configure.dart';
import 'server/logs_page.dart';
import 'log.dart';

final routes = {
  '/file_explorer': (BuildContext context) => FileExplorerPage(),
  '/settings': (BuildContext context) => SettingsPage(),
  '/server_config': (BuildContext context) => ConfigureServerPage(),
  '/logs': (BuildContext context) => LogsPage(),
  '/add_data_link_manual': (BuildContext context) => AddDataLinkManual(),
  '/console': (BuildContext context) => DeviceConsolePage(log),
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

void main() {
  initConf().then((_) {
    state = AppState(verbose: true);
    runApp(MyApp());
    state.init();
  });
}
