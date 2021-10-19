import 'package:flutter/material.dart';
import 'package:scrabble_cheater/screens/main_screen.dart';

class App extends StatelessWidget{

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primaryColor: Colors.blue,
    ),
    home: MainPage(),
  );
}