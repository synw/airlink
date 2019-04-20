import 'package:flutter/material.dart';
import 'conf.dart';
import 'intro.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Airlink',
      home: IntroPage(),
      theme: ThemeData.dark(),
    );
  }
}

void main() async {
  initConf();
  runApp(MyApp());
}
