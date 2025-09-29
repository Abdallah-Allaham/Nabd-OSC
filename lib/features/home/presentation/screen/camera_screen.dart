import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:navia/features/home/presentation/cubit/yuv_to_jpeg_fallback.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cam;
  IOWebSocketChannel? _ch;
  StreamSubscription? _wsSubscription;
  final String serverUrl = 'wss://bae61170b508.ngrok-free.app/ws/guidance';

  // Guidance vars
  String? _direction = 'steady';
  double _conf = 0.0, _coverage = 0.0, _magnitude = 0.0;
  bool _readyForCapture = false;

  // Frame throttling
  int lastSentMs = 0;
  int get minGapMs => 1000 ~/ 10; // 10 FPS ثابت
  int _frameCounter = 0;
  final Queue<CameraImage> _frameQueue = Queue();
  bool _isProcessingQueue = false;

  bool _isCapturing = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _requestCameraAndStart();
  }

  Future<void> _requestCameraAndStart() async {
    if (await Permission.camera.request().isGranted) {
      await _initializeCamera();
      _connectWebSocket();
    } else {
      // show dialog if needed
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _ch?.sink.close();
    _cam?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _cam = CameraController(
      cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back),
      ResolutionPreset.medium,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await _cam?.initialize();
    setState(() {});
    await _cam?.startImageStream(_onFrame);
  }

  void _connectWebSocket() {
    _ch = IOWebSocketChannel.connect(Uri.parse(serverUrl));
    _wsSubscription = _ch!.stream.listen((data) {
      try {
        final m = jsonDecode(data.toString());
        if (m['type'] == 'guidance') {
          setState(() {
            _direction = m['dir'];
            _magnitude = (m['magnitude'] ?? 0.0).toDouble();
            _coverage  = (m['coverage'] ?? 0.0).toDouble();
            _conf      = (m['conf'] ?? 0.0).toDouble();
            _readyForCapture = m['ready'] == true;
          });
        }
      } catch (_) {}
    });
  }

  void _onFrame(CameraImage image) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_ch == null) return;
    if (now - lastSentMs < minGapMs) return;

    if (_frameQueue.length >= 3) _frameQueue.removeFirst();
    _frameQueue.add(image);
    if (!_isProcessingQueue) _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _frameQueue.isEmpty) return;
    _isProcessingQueue = true;
    while (_frameQueue.isNotEmpty && _ch != null) {
      final image = _frameQueue.removeFirst();
      try {
        final jpegBytes = await YuvToJpegFallback.convert(image, 60);
        _frameCounter++;
        final frameMeta = {
          'type': 'frame_meta',
          'seq': _frameCounter,
          'ts': DateTime.now().millisecondsSinceEpoch,
          'w': 640, 'h': 480, 'rotationDegrees': 0, 'jpegQuality': 60,
        };
        _ch?.sink.add(jsonEncode(frameMeta));
        _ch?.sink.add(jpegBytes);
        lastSentMs = DateTime.now().millisecondsSinceEpoch;
      } catch (_) {}
      if (_frameQueue.isNotEmpty) await Future.delayed(const Duration(milliseconds: 1));
    }
    _isProcessingQueue = false;
  }

  // التقاط صورة عادي (مع حفظ الصورة في الجهاز)
  Future<void> _takePicture() async {
    if (_cam == null || !_cam!.value.isInitialized) return;
    setState(() { _isCapturing = true; });

    try {
      final XFile image = await _cam!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() { _isCapturing = false; });
      // اعرض رسالة خطأ لو بدك
    }
  }

  IconData _getDirectionIcon(String? direction) {
    switch (direction) {
      case 'up': return Icons.keyboard_arrow_up;
      case 'down': return Icons.keyboard_arrow_down;
      case 'left': return Icons.keyboard_arrow_left;
      case 'right': return Icons.keyboard_arrow_right;
      case 'rotateCW': return Icons.rotate_right;
      case 'rotateCCW': return Icons.rotate_left;
      default: return Icons.center_focus_strong;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_cam?.value.isInitialized == true)
            Positioned.fill(child: CameraPreview(_cam!))
          else
            const Center(child: CircularProgressIndicator()),

          // توجيه Guidance Overlay
          if (_cam?.value.isInitialized == true)
            Positioned(
              left: 0, right: 0, bottom: 30,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_getDirectionIcon(_direction), size: 60,
                      color: _direction == 'steady' ? Colors.green : Colors.orange),
                  Text(
                    'Direction: ${_direction?.toUpperCase()}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Conf: ${(_conf * 100).toStringAsFixed(1)}%   ",
                          style: const TextStyle(color: Colors.white)),
                      Text("Cov: ${(_coverage * 100).toStringAsFixed(1)}%",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  if (_readyForCapture)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(30)),
                      child: const Text("جاهز لالتقاط الصورة!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),

          // زر التقاط الصورة
          if (_cam?.value.isInitialized == true)
            Positioned(
              left: 0, right: 0, bottom: 70,
              child: Center(
                child: GestureDetector(
                  onTap: _isCapturing ? null : _takePicture,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: _isCapturing
                        ? const Center(child: SizedBox(
                      width: 30, height: 30,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                    ))
                        : Container(
                      margin: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // عرض الصورة الملتقطة (اختياري)
          if (_capturedImagePath != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 300,
                        height: 400,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(_capturedImagePath!)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() { _capturedImagePath = null; });
                            },
                            child: const Text('إعادة الالتقاط'),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('حفظ/خروج'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
