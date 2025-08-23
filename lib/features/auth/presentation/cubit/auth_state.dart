part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthAuthenticatedForLogin extends AuthState {
  final UserEntity user;

  const AuthAuthenticatedForLogin({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthOtpSentForSignup extends AuthState {
  final String phoneNumber;
  final String? verificationId;

  const AuthOtpSentForSignup({required this.phoneNumber, this.verificationId});

  @override
  List<Object> get props => [phoneNumber, verificationId ?? ''];
}

class AuthOtpSentForLogin extends AuthState {
  final String phoneNumber;
  final String? verificationId;

  const AuthOtpSentForLogin({required this.phoneNumber, this.verificationId});

  @override
  List<Object> get props => [phoneNumber, verificationId ?? ''];
}

class AuthSignupSuccess extends AuthState {
  final String message;

  const AuthSignupSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthListeningForSpeech extends AuthState {}

class AuthStoppedListeningForSpeech extends AuthState {}

class AuthSpeechResult extends AuthState {
  final String recognizedText;

  const AuthSpeechResult({required this.recognizedText});

  @override
  List<Object> get props => [recognizedText];
}

class AuthSpeechComplete extends AuthState {
  final String recognizedText;

  const AuthSpeechComplete({required this.recognizedText});

  @override
  List<Object> get props => [recognizedText];
}

class VoiceIdEnrollmentStarted extends AuthState {}

class VoiceIdEnrollmentComplete extends AuthState {
  final String message;
  final String voiceProfileUrl;

  const VoiceIdEnrollmentComplete({
    required this.message,
    required this.voiceProfileUrl,
  });

  @override
  List<Object> get props => [message, voiceProfileUrl];
}

class VoiceIdEnrollmentError extends AuthState {
  final String message;

  const VoiceIdEnrollmentError({required this.message});

  @override
  List<Object> get props => [message];
}
