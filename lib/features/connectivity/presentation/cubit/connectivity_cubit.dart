import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/utils/secure_storage_helper.dart';
import '../../../../core/constants/app_constants.dart';
import 'connectivity_state.dart';
import '../../../connectivity/data/bridge/connectivity_channel.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  final FeedbackService _feedbackService = FeedbackService();
  final SecureStorageHelper _secureStorage = SecureStorageHelper();
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;

  ConnectivityCubit() : super(ConnectivityIdle()) {
    _setupEventSubscription();
  }

  void _setupEventSubscription() {
    _eventSubscription = ConnectivityChannel.eventStream.listen((event) {
      switch (event['type']) {
        case 'qr_visible':
          _handleQrVisible();
          break;
        case 'qr_parsed':
          _handleQrParsed(event['ssid'], event['password']);
          break;
        case 'capture_blocked':
          _handleCaptureBlocked();
          break;
        case 'failure':
          _handleFailure(event['reason']);
          break;
      }
    });
  }

  Future<void> startFlow(BuildContext context) async {
    if (state is ConnectivityIdle) {
      emit(ConnectivityOpeningSettings());
      _feedbackService.announce('opening_wifi_settings', context);
      
      // Request screen capture permission
      final hasPermission = await ConnectivityChannel.requestScreenCapture();
      if (!hasPermission) {
        emit(ConnectivityError(reason: 'permission_denied'));
        return;
      }

      // Open Wi-Fi settings
      await ConnectivityChannel.openWifiSettings();
    }
  }

  void _handleQrVisible() {
    if (state is ConnectivityOpeningSettings) {
      emit(ConnectivityCapturing());
      ConnectivityChannel.captureOnce();
    }
  }

  Future<void> _handleQrParsed(String ssid, String password) async {
    if (state is ConnectivityCapturing) {
      // Get UID from secure storage
      final uid = await _secureStorage.getPrefString(
        key: AppConstants.uidKey,
        defaultValue: '',
      );

      emit(ConnectivityReady(
        ssid: ssid,
        password: password,
        uid: uid.isNotEmpty ? uid : null,
      ));

      // Note: We can't announce here without context, so we'll handle this in the UI
    }
  }

  void _handleCaptureBlocked() {
    if (state is ConnectivityCapturing) {
      emit(ConnectivityFallback());
      // Note: We can't announce here without context, so we'll handle this in the UI
    }
  }

  void _handleFailure(String reason) {
    emit(ConnectivityError(reason: reason));
  }

  String getFinalJson() {
    if (state is ConnectivityReady) {
      final readyState = state as ConnectivityReady;
      final Map<String, String> json = {
        'ssid': readyState.ssid,
        'password': readyState.password,
      };
      
      if (readyState.uid != null) {
        json['uid'] = readyState.uid!;
      }
      
      return jsonEncode(json);
    }
    return '';
  }

  @override
  Future<void> close() {
    _eventSubscription?.cancel();
    return super.close();
  }
}