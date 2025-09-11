import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

part 'guided_capture_state.dart';

class GuidedCaptureCubit extends Cubit<GuidedCaptureState> {
  Timer? _sessionTimer;
  
  GuidedCaptureCubit() : super(GuidedCaptureInitial());

  void startFromVoiceOrButton() {
    emit(GuidedCaptureOverlayVisible());
    _startSessionTimer();
  }

  void onBackPressed() {
    _cleanup();
    emit(GuidedCaptureCancelled());
  }

  void onSessionTimeout() {
    _cleanup();
    emit(GuidedCaptureTimeout());
  }

  void onCaptureComplete(String docId) {
    _cleanup();
    emit(GuidedCaptureDone(docId: docId));
  }

  void onCaptureError(String message) {
    _cleanup();
    emit(GuidedCaptureError(message: message));
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(const Duration(seconds: 15), () {
      onSessionTimeout();
    });
  }

  void _cleanup() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  @override
  Future<void> close() {
    _cleanup();
    return super.close();
  }
}

