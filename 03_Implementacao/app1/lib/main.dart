import 'package:app1/home_menu.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Crash',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeMenu(),
    );
  }
}
