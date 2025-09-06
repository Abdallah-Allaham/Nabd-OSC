import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الكاميرا'),
      ),
      body: Center(
        child: Text(
          "هنا ستظهر الكاميرا",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
