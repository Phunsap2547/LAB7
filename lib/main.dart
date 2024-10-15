import 'package:flutter/material.dart';
import 'model/login.dart';
import 'model/signin.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(), // เปลี่ยนหน้าหลักที่นี่
      routes: {
        '/signin': (context) => SigninPage(), // กำหนดเส้นทางที่นี่
      },
    );
  }
}
