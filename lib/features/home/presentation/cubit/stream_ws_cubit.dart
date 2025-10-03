import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/web_socket_client.dart';

abstract class StreamWsState {
  final int targetFps;
  final String? guidanceDirection;
  final double coverage;
  final double confidence;
  final bool readyForCapture;

  const StreamWsState({
    this.targetFps = 20,
    this.guidanceDirection,
    this.coverage = 0.0,
    this.confidence = 0.0,
    this.readyForCapture = false,
  });
}

class InitialState extends StreamWsState {
  const InitialState({
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
  });
}

class ConnectingState extends StreamWsState {
  const ConnectingState({
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
  });
}

class StreamingState extends StreamWsState {
  const StreamingState({
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
  });
}

class FailureState extends StreamWsState {
  final String message;

  const FailureState({
    required this.message,
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
  });
}

class StreamWsCubit extends Cubit<StreamWsState> {
  final WebSocketClient _webSocketClient;

  StreamWsCubit(this._webSocketClient) : super(const InitialState());

  Future<void> startConnection() async {
    await _webSocketClient.connect(
          (message) {
        _handleWebSocketMessage(message);
      },
          (error) {
        emit(FailureState(message: error));
      },
    );
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'guidance') {
        final direction = data['class'] ?? 'no_document';
        final coverage = (data['coverage'] ?? 0.0).toDouble();
        final confidence = (data['conf'] ?? 0.0).toDouble();
        final ready = data['ready'] ?? false;
        updateGuidance(direction, coverage, confidence, ready);
      }
    } catch (e) {
      emit(FailureState(message: "Failed to parse WebSocket message"));
    }
  }

  void updateGuidance(String direction, double coverage, double confidence, bool ready) {
    emit(StreamingState(
      guidanceDirection: direction,
      coverage: coverage,
      confidence: confidence,
      readyForCapture: ready,
    ));
  }

  void setFailure(String message) {
    emit(FailureState(message: message));
  }

  void stopConnection() {
    _webSocketClient.close();
    emit(InitialState());
  }
}
