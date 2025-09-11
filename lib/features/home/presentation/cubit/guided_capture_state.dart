part of 'guided_capture_cubit.dart';

abstract class GuidedCaptureState extends Equatable {
  const GuidedCaptureState();

  @override
  List<Object> get props => [];
}

class GuidedCaptureInitial extends GuidedCaptureState {}

class GuidedCaptureOverlayVisible extends GuidedCaptureState {}

class GuidedCaptureCancelled extends GuidedCaptureState {}

class GuidedCaptureTimeout extends GuidedCaptureState {}

class GuidedCaptureDone extends GuidedCaptureState {
  final String docId;
  
  const GuidedCaptureDone({required this.docId});
  
  @override
  List<Object> get props => [docId];
}

class GuidedCaptureError extends GuidedCaptureState {
  final String message;
  
  const GuidedCaptureError({required this.message});
  
  @override
  List<Object> get props => [message];
}

