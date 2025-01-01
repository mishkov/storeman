import 'package:flutter/material.dart';
import 'package:storeman/home_screen.dart';

class StoremanApp extends StatelessWidget {
  const StoremanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
