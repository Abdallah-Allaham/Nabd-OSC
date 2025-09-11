import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _capturedImagePath;
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Request camera permission
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
          
          // Provide feedback after camera is fully initialized (with delay)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _provideCameraOpenedFeedback();
            }
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
      _showErrorDialog(AppLocalizations.of(context)!.failedToInitializeCamera + ': $e');
    }
  }

  void _provideCameraOpenedFeedback() {
    final l10n = AppLocalizations.of(context)!;
    _feedbackService.announce(l10n.cameraOpened, context);
    _feedbackService.vibrateLight();
    _feedbackService.playSuccessTone();
  }

  void _showPermissionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
      builder: (context) => AlertDialog(
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

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    // Provide feedback when capture starts
    _feedbackService.vibrateMedium();
    _feedbackService.playLoadingTone();

    try {
      final XFile image = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = image.path;
        _isCapturing = false;
      });
      
      // Provide success feedback
      final l10n = AppLocalizations.of(context)!;
      _feedbackService.announce(l10n.photoCapturedSuccessfully, context);
      _feedbackService.vibrateLight();
      _feedbackService.playSuccessTone();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.photoCapturedSuccessfully),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isCapturing = false;
      });
      final l10n = AppLocalizations.of(context)!;
      _showErrorDialog(l10n.failedToCapturePhoto + ': $e');
    }
  }

  void _onBackPressed() {
    final l10n = AppLocalizations.of(context)!;
    _feedbackService.announce(l10n.cameraClosed, context);
    _feedbackService.vibrateLight();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return WillPopScope(
      onWillPop: () async {
        _onBackPressed();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // REAL CAMERA PREVIEW
            if (_isInitialized && _cameraController != null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l10n.cameraInitializing,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top bar with back button and title
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _onBackPressed,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.camera,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 60), // Balance the back button
                  ],
                ),
              ),
            ),

            // Bottom controls - ONLY CAPTURE BUTTON
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Center(
                  child: GestureDetector(
                    onTap: _isCapturing ? null : _takePicture,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Captured image overlay (if any)
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
                                _feedbackService.vibrateSelection();
                                setState(() {
                                  _capturedImagePath = null;
                                });
                              },
                              child: Text(l10n.retake),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed: () {
                                _feedbackService.vibrateSelection();
                                _feedbackService.playSuccessTone();
                                Navigator.pop(context);
                              },
                              child: Text(l10n.save),
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
      ),
    );
  }
}