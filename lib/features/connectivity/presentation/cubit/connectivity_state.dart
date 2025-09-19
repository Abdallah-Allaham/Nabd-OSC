import 'package:equatable/equatable.dart';

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityIdle extends ConnectivityState {}

class ConnectivityOpeningSettings extends ConnectivityState {}

class ConnectivityCapturing extends ConnectivityState {}

class ConnectivityReady extends ConnectivityState {
  final String ssid;
  final String password;
  final String? uid;

  const ConnectivityReady({
    required this.ssid,
    required this.password,
    this.uid,
  });

  @override
  List<Object?> get props => [ssid, password, uid];
}

class ConnectivityFallback extends ConnectivityState {}

class ConnectivityError extends ConnectivityState {
  final String reason;

  const ConnectivityError({required this.reason});

  @override
  List<Object?> get props => [reason];
}
