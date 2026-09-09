import 'package:flutter/material.dart';
import 'package:icrash_app/home_menu.dart';
import 'package:icrash_app/src/data/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapFirebase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I-Crash',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeMenu(),
    );
  }
}
