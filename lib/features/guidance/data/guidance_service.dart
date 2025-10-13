import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

import 'yuv_to_jpeg_converter.dart';

typedef GuidanceCallback =
    void Function({
      required String direction,
      required double coverage,
      required double confidence,
      required bool ready,
    });

class GuidanceService {
  final String serverUrl;
  final int targetFps;

  CameraController? _camera;
  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  Timer? _hbTimer;
  bool _connected = false;

  bool _isProcessing = false;
  int _lastSentMs = 0;

  int get _minGapMs => (1000 ~/ targetFps);
  int _seq = 0;

  bool _isStreaming = false;

  GuidanceService({required this.serverUrl, this.targetFps = 20});

  Future<void> start({
    required GuidanceCallback onGuidance,
    required Function(String) onError,
  }) async {
    try {
      final cameras = await availableCameras();
      _camera = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.yuv420,
        enableAudio: false,
      );
      await _camera!.initialize();

      try {
        await _camera!.setFocusMode(FocusMode.auto);
      } catch (_) {}
      try {
        await _camera!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      try {
        final minZoom = await _camera!.getMinZoomLevel();
        await _camera!.setZoomLevel(minZoom);
      } catch (_) {}

      try {
        await _camera!.setFlashMode(FlashMode.torch);
      } catch (_) {}

      _channel = IOWebSocketChannel.connect(Uri.parse(serverUrl));
      _wsSub = _channel!.stream.listen(
        (data) {
          try {
            final m = jsonDecode(data.toString()) as Map<String, dynamic>;
            if (m['type'] == 'guidance') {
              onGuidance(
                direction: (m['class'] as String?) ?? 'no_document',
                coverage: (m['coverage'] ?? 0.0).toDouble(),
                confidence: (m['conf'] ?? 0.0).toDouble(),
                ready: (m['ready'] ?? false) == true,
              );
            } else if (m['type'] == 'hb') {
              // heartbeat from server; do nothing (keeps connection alive)
            }
          } catch (_) {}
        },
        onError: (e) {
          onError('WebSocket error: $e');
          _connected = false;
        },
        onDone: () {
          onError('WebSocket closed');
          _connected = false;
        },
      );

      _connected = true;
      _startHeartbeat();

      _isStreaming = true;
      await _camera!.startImageStream(_onFrame);
    } catch (e) {
      onError('Start failed: $e');
    }
  }

  Future<void> pauseStreaming() async {
    if (_camera?.value.isStreamingImages == true) {
      await _camera!.stopImageStream();
    }
    _isStreaming = false;
  }

  Future<void> resumeStreaming() async {
    if (_camera != null && _camera!.value.isInitialized && !_isStreaming) {
      await _camera!.startImageStream(_onFrame);
      _isStreaming = true;
    }
  }

  Future<void> stop() async {
    try {
      try {
        await _camera?.setFlashMode(FlashMode.off);
      } catch (_) {}
      if (_camera?.value.isStreamingImages == true) {
        await _camera?.stopImageStream();
      }
    } catch (_) {}
    _hbTimer?.cancel();
    _wsSub?.cancel();
    _channel?.sink.close();
    _channel = null;
    await _camera?.dispose();
    _camera = null;
    _connected = false;
  }

  Future<void> _onFrame(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_channel == null) return;
    if (_isProcessing) return;
    if (now - _lastSentMs < _minGapMs) return;
    _isProcessing = true;
    try {
      final jpeg = await YuvToJpegConverter.convert(image, 80);
      if (jpeg.isNotEmpty && _channel != null) {
        _seq += 1;
        final meta = {
          'type': 'frame_meta',
          'seq': _seq,
          'ts': DateTime.now().millisecondsSinceEpoch,
          'w': image.width,
          'h': image.height,
          'rotation_degrees': 0,
          'jpeg_quality': 80,
        };
        _channel!.sink.add(jsonEncode(meta));
        _channel!.sink.add(jpeg);
        _lastSentMs = now;
      }
    } catch (_) {}
    _isProcessing = false;
  }

  CameraController? get cameraController => _camera;

  bool get isConnected => _connected;

  void _startHeartbeat() {
    _hbTimer?.cancel();
    _hbTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      try {
        if (_channel != null) {
          _channel!.sink.add(jsonEncode({'type': 'hb'}));
        }
      } catch (_) {}
    });
  }
}
