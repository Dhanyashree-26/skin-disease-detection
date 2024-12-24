import 'package:flutter/material.dart';
import 'screens/skin.dart'; // Import the `DiseaseInfoScreen`

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skin Disease Detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DiseaseInfoScreen(), // Set `DiseaseInfoScreen` as the home screen
    );
  }
}
