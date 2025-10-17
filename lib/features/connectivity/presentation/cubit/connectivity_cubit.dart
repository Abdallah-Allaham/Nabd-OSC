import 'package:flutter_bloc/flutter_bloc.dart';
import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {

  ConnectivityCubit() : super(ConnectivityIdle());

  void showSuccess() {
    emit(ConnectivitySuccess());
  }

  void showError(String reason) {
    emit(ConnectivityError(reason: reason));
  }
}