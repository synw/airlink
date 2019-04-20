import 'package:flutter/material.dart';
import 'conf.dart';
import 'file_explorer.dart';

class _IntroPageState extends State<IntroPage> {
  @override
  void initState() {
    onConfReady.then((_) {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (BuildContext context) {
        return DataviewPage("/");
      }));
    });
    super.initState();
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
            Padding(padding: EdgeInsets.only(bottom: 15.0)),
            CircularProgressIndicator(backgroundColor: Colors.grey),
          ],
        )));
  }
}

class IntroPage extends StatefulWidget {
  @override
  _IntroPageState createState() => _IntroPageState();
}
