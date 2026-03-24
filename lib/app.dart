import 'package:flutter/material.dart';

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
      home: const Scaffold(
        body: Center(
          child: Text('Algo Canvas'),
        ),
      ),
    );
  }
}
