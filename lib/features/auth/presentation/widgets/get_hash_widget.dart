import 'package:flutter/material.dart';
import 'package:sms_autofill/sms_autofill.dart';

class GetAppHashWidget extends StatefulWidget {
  const GetAppHashWidget({super.key});

  @override
  State<GetAppHashWidget> createState() => _GetAppHashWidgetState();
}

class _GetAppHashWidgetState extends State<GetAppHashWidget> {
  String _appSignature = '';

  @override
  void initState() {
    super.initState();
    _getAppSignature();
  }

  void _getAppSignature() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      setState(() {
        _appSignature = signature;
      });
      print('Firebase App Signature Hash: $signature');
    } catch (e) {
      print('Failed to get app signature: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'اضغط على الزر لاستخراج Hash التطبيق',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _getAppSignature,
            child: const Text('استخراج الـ Hash'),
          ),
          const SizedBox(height: 20),
          Text(
            'Hash التطبيق: $_appSignature',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

