import 'package:flutter/material.dart';
import 'core/config/environment.dart';

void main() {
  Environment.name = 'dev';
  runApp(const Chopper());
}

class Chopper extends StatelessWidget {
  const Chopper({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Chopper',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    ),
    home: const Scaffold(
      body: Center(
        child: Text('Chopper App'),
      ),
    ),
  );
}