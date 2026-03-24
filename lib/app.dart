import 'package:flutter/material.dart';
import 'package:algo_canvas/screens/home_screen.dart';

class AlgoCanvasApp extends StatelessWidget {
  const AlgoCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Algo Canvas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
