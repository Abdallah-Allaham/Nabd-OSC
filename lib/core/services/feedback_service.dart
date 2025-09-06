import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();

  factory FeedbackService() {
    return _instance;
  }

  FeedbackService._internal();

  static const _platform = MethodChannel('navia/feedback');

  void announce(String message, BuildContext context) {
    final TextDirection direction = Directionality.of(context);
    SemanticsService.announce(message, direction);
  }

  void vibrate() {
    HapticFeedback.vibrate();
  }

  void vibrateLight() {
    HapticFeedback.lightImpact();
  }

  void vibrateMedium() {
    HapticFeedback.mediumImpact();
  }

  void vibrateHeavy() {
    HapticFeedback.heavyImpact();
  }

  void vibrateSelection() {
    HapticFeedback.selectionClick();
  }

  void playSuccessTone() {
    try {
      _platform.invokeMethod('playSuccessTone');
    } on PlatformException catch (e) {
      print("Failed to play success tone: ${e.message}");
    }
  }

  void playFailureTone() {
    try {
      _platform.invokeMethod('playFailureTone');
    } on PlatformException catch (e) {
      print("Failed to play failure tone: ${e.message}");
    }
  }

  void playLoadingTone() {
    try {
      _platform.invokeMethod('playLoadingTone');
    } on PlatformException catch (e) {
      print("Failed to play loading tone: ${e.message}");
    }
  }

  void playWaitingTone() {
    try {
      _platform.invokeMethod('playWaitingTone');
    } on PlatformException catch (e) {
      print("Failed to play waiting tone: ${e.message}");
    }
  }
}