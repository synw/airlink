import 'package:flutter/material.dart';
import 'state.dart';

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      state.onReady.then((_) {
        Navigator.of(context).pushReplacementNamed("/file_explorer");
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(color: Colors.white),
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset("assets/logo_txt.png"),
            const Padding(padding: EdgeInsets.only(bottom: 15.0)),
            const CircularProgressIndicator(backgroundColor: Colors.grey),
          ],
        )));
  }
}

class IntroPage extends StatefulWidget {
  @override
  _IntroPageState createState() => _IntroPageState();
}
