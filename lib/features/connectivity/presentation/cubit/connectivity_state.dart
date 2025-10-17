import 'package:equatable/equatable.dart';

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();

  @override
  List<Object?> get props => [];
}

class ConnectivityIdle extends ConnectivityState {}




class ConnectivitySuccess extends ConnectivityState {}


class ConnectivityError extends ConnectivityState {
  final String reason;

  const ConnectivityError({required this.reason});

  @override
  List<Object?> get props => [reason];
}
