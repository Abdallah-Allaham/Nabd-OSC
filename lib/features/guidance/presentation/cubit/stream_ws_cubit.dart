import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/guidance_service.dart';
import 'stream_ws_state.dart';

class StreamWsCubit extends Cubit<StreamWsState> {
  final GuidanceService _service;

  StreamWsCubit(this._service) : super(const InitialState());

  Future<void> start() async {
    emit(const ConnectingState());
    await _service.start(
      onGuidance: ({required direction, required coverage, required confidence, required ready}) {
        emit(StreamingState(
          guidanceDirection: direction,
          coverage: coverage,
          confidence: confidence,
          readyForCapture: ready,
          connected: _service.isConnected,
        ));
      },
      onError: (err) {
        emit(FailureState(message: err, connected: _service.isConnected));
      },
    );
  }

  Future<void> stop() async {
    await _service.stop();
    emit(const InitialState());
  }
}


