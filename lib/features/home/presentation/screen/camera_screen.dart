import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:image/image.dart' as img_lib;

import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/stream_ws_cubit.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  WebSocketChannel? _channel;
  final FeedbackService _feedbackService = FeedbackService();
  String _guidanceText = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    context.read<StreamWsCubit>().startConnection();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _startStreaming();
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorDialog('Failed to initialize camera');
    }
  }

  void _startStreaming() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      _cameraController!.startImageStream((CameraImage image) {
        _sendFrameToServer(image);
      });
    }
  }

  Future<void> _sendFrameToServer(CameraImage image) async {
    final quality = 80; // Adjust quality
    final jpegBytes = await _convertYuvToJpeg(image, quality);
    if (jpegBytes.isNotEmpty && _channel != null) {
      final frameMeta = {
        'type': 'frame_meta',
        'seq': 1,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'w': image.width,
        'h': image.height,
        'rotation_degrees': 0,
        'jpeg_quality': quality,
      };
      _channel?.sink.add(jsonEncode(frameMeta));
      _channel?.sink.add(jpegBytes);
    }
  }

  Future<Uint8List> _convertYuvToJpeg(CameraImage image, int quality) async {
    final payload = {
      'width': image.width,
      'height': image.height,
      'y': image.planes[0].bytes,
      'u': image.planes[1].bytes,
      'v': image.planes[2].bytes,
      'yRowStride': image.planes[0].bytesPerRow,
      'uRowStride': image.planes[1].bytesPerRow,
      'vRowStride': image.planes[2].bytesPerRow,
      'uPixelStride': image.planes[1].bytesPerPixel ?? 1,
      'vPixelStride': image.planes[2].bytesPerPixel ?? 1,
      'quality': quality,
    };

    return compute(_convertInIsolate, payload);
  }

  static Uint8List _convertInIsolate(Map<String, dynamic> p) {
    final width = p['width'] as int;
    final height = p['height'] as int;
    final y = p['y'] as Uint8List;
    final u = p['u'] as Uint8List;
    final v = p['v'] as Uint8List;
    final yRow = p['yRowStride'] as int;
    final uRow = p['uRowStride'] as int;
    final vRow = p['vRowStride'] as int;
    final uPix = p['uPixelStride'] as int;
    final vPix = p['vPixelStride'] as int;
    final quality = p['quality'] as int;

    final img = img_lib.Image(width: width, height: height);
    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final yIdx = row * yRow + col;
        final uvRow = row >> 1;
        final uvCol = col >> 1;
        final uIdx = uvRow * uRow + uvCol * uPix;
        final vIdx = uvRow * vRow + uvCol * vPix;

        final yy = y[yIdx];
        final uu = u[uIdx] - 128;
        final vv = v[vIdx] - 128;

        int r = (yy + 1.402 * vv).round();
        int g = (yy - 0.344136 * uu - 0.714136 * vv).round();
        int b = (yy + 1.772 * uu).round();

        if (r < 0)
          r = 0;
        else if (r > 255)
          r = 255;
        if (g < 0)
          g = 0;
        else if (g > 255)
          g = 255;
        if (b < 0)
          b = 0;
        else if (b > 255)
          b = 255;

        img.setPixelRgb(col, row, r, g, b);
      }
    }

    final rotatedImg = img_lib.copyRotate(img, angle: 90);
    return Uint8List.fromList(img_lib.encodeJpg(rotatedImg, quality: quality));
  }

  void _showPermissionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.cameraPermissionRequired),
            content: Text(l10n.cameraPermissionMessage),
            actions: [
              TextButton(
                onPressed: () {
                  _feedbackService.vibrateSelection();
                  Navigator.pop(context);
                },
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () {
                  _feedbackService.vibrateSelection();
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: Text(l10n.settings),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    final l10n = AppLocalizations.of(context)!;
    _feedbackService.playFailureTone();
    _feedbackService.vibrateMedium();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.cameraError),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  _feedbackService.vibrateSelection();
                  Navigator.pop(context);
                },
                child: Text(l10n.cancel),
              ),
            ],
          ),
    );
  }

  void _updateGuidanceText(String direction) {
    setState(() {
      switch (direction) {
        case 'top_left':
          _guidanceText = 'Move camera up and left';
          break;
        case 'top_right':
          _guidanceText = 'Move camera up and right';
          break;
        case 'bottom_left':
          _guidanceText = 'Move camera down and left';
          break;
        case 'bottom_right':
          _guidanceText = 'Move camera down and right';
          break;
        case 'perfect':
          _guidanceText = 'Perfect framing!';
          break;
        case 'no_document':
          _guidanceText = 'No document detected';
          break;
        default:
          _guidanceText = 'Unknown direction';
      }
    });
  }

  @override
  void dispose() {
    print("📱 Disposing camera screen...");
    
    // إزالة lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // إيقاف WebSocket connection
    _channel?.sink.close();
    _channel = null;
    
    // إيقاف StreamWsCubit
    try {
      context.read<StreamWsCubit>().stopConnection();
    } catch (e) {
      print("Error stopping StreamWsCubit: $e");
    }
    
    // إيقاف الكاميرا بشكل آمن
    _cameraController?.dispose();
    _cameraController = null;
    
    // إعادة تعيين المتغيرات
    _isInitialized = false;
    _isCapturing = false;
    
    print("📱 Camera screen disposed successfully");
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // التطبيق ذهب للخلفية - إيقاف الكاميرا فوراً
        print("📱 App backgrounded - Stopping camera");
        _stopCamera();
        break;
      case AppLifecycleState.resumed:
        // التطبيق عاد للمقدمة - إعادة تشغيل الكاميرا
        print("📱 App resumed - Restarting camera");
        _initializeCamera();
        break;
    }
  }

  void _stopCamera() {
    try {
      _cameraController?.dispose();
      _cameraController = null;
      _isInitialized = false;
      _isCapturing = false;
      
      // إيقاف WebSocket
      _channel?.sink.close();
      _channel = null;
      
      context.read<StreamWsCubit>().stopConnection();
    } catch (e) {
      print("Error stopping camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isInitialized)
              Column(
                children: [
                  CameraPreview(_cameraController!),
                  SizedBox(height: 20),
                  Text(
                    _guidanceText,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Start Streaming'),
                  ),
                ],
              )
            else
              CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
