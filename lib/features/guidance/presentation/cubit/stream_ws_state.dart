abstract class StreamWsState {
  final int targetFps;
  final String? guidanceDirection;
  final double coverage;
  final double confidence;
  final bool readyForCapture;
  final bool connected;
  final bool loading;
  final String? sessionId;
  
  const StreamWsState({
    this.targetFps = 20,
    this.guidanceDirection,
    this.coverage = 0.0,
    this.confidence = 0.0,
    this.readyForCapture = false,
    this.connected = false,
    this.loading = false,
    this.sessionId,
  });
}

class InitialState extends StreamWsState {
  const InitialState({
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
    super.connected,
    super.loading,
    super.sessionId,
  });
}

class ConnectingState extends StreamWsState {
  const ConnectingState({
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
    super.connected,
    super.loading,
    super.sessionId,
  });
}

class StreamingState extends StreamWsState {
  const StreamingState({
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
    super.connected,
    super.loading,
    super.sessionId,
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
    super.connected,
    super.loading,
    super.sessionId,
  });
}

class LoadingState extends StreamWsState {
  final String? savedPath;
  const LoadingState({
    required String sessionId,
    this.savedPath,
    super.targetFps,
    super.guidanceDirection,
    super.coverage,
    super.confidence,
    super.readyForCapture,
    super.connected,
  }) : super(
    loading: true,
    sessionId: sessionId,
  );
}



