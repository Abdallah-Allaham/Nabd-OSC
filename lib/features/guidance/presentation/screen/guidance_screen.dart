import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../cubit/stream_ws_cubit.dart';
import '../cubit/stream_ws_state.dart';
import '../../data/guidance_service.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../l10n/app_localizations.dart';
import 'dart:ui' show ImageFilter;

class GuidanceScreen extends StatefulWidget {
  const GuidanceScreen({super.key});

  @override
  State<GuidanceScreen> createState() => _GuidanceScreenState();
}

class _GuidanceScreenState extends State<GuidanceScreen> {
  late final GuidanceService _service;
  StreamWsCubit? _cubit;
  final FeedbackService _feedback = FeedbackService();
  String? _lastAnnouncedDirection;
  int _lastAnnounceMs = 0;

  static const int _announceCooldownMs = 1500;

  IconData _iconForDirection(String? direction) {
    switch (direction) {
      // Inverse: tell user how to MOVE the camera
      case 'top_left':
        return Icons.south_east; // move down-right
      case 'top_right':
        return Icons.south_west; // move down-left
      case 'bottom_left':
        return Icons.north_east; // move up-right
      case 'bottom_right':
        return Icons.north_west; // move up-left
      case 'paper_face_only':
        return Icons.center_focus_strong;
      case 'perfect':
        return Icons.check_circle;
      case 'no_document':
        return Icons.help_outline;
      default:
        return Icons.center_focus_strong;
    }
  }

  Color _colorForDirection(String? direction) {
    switch (direction) {
      case 'perfect':
        return Colors.green;
      case 'paper_face_only':
        return Colors.blue;
      case 'no_document':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _promptForDirection(String? direction) {
    final l10n = AppLocalizations.of(context)!;
    switch (direction) {
      case 'top_left':
        return l10n.guidance_move_down_right;
      case 'top_right':
        return l10n.guidance_move_down_left;
      case 'bottom_left':
        return l10n.guidance_move_up_right;
      case 'bottom_right':
        return l10n.guidance_move_up_left;
      case 'paper_face_only':
        return l10n.guidance_move_away;
      case 'perfect':
        return l10n.guidance_perfect;
      case 'no_document':
        return l10n.guidance_no_document;
      default:
        return l10n.guidance_unknown;
    }
  }

  void _maybeAnnounce(BuildContext context, String? direction) {
    if (direction == null || direction.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final changed = direction != _lastAnnouncedDirection;
    final cooledDown = now - _lastAnnounceMs >= _announceCooldownMs;
    if (changed && cooledDown) {
      final msg = _promptForDirection(direction);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final l10n = AppLocalizations.of(context)!;
        _feedback.announce(msg, context);
        if (direction == 'perfect') {
          _feedback.vibrateMedium();
          _feedback.playSuccessTone();
        } else if (direction == 'paper_face_only') {
          _feedback.vibrateSelection();
          _feedback.announce(l10n.guidance_away_and_raise, context);
        } else {
          _feedback.vibrateSelection();
          _feedback.announce(l10n.guidance_raise_phone, context);
        }
      });
      _lastAnnouncedDirection = direction;
      _lastAnnounceMs = now;
    }
  }

  @override
  void initState() {
    super.initState();
    _service = GuidanceService(
      serverUrl: 'wss://fd3cbac4d085.ngrok-free.app/ws/guidance',
    );
  }

  @override
  void dispose() {
    _cubit?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        _cubit = StreamWsCubit(_service)..start();
        return _cubit!;
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocConsumer<StreamWsCubit, StreamWsState>(
            listener: (context, state) {
              if (state is LoadingState) {
                _feedback.announce(
                  'تم الالتقاط، جاري المعالجة',
                  context,
                );
              }
            },
            builder: (context, state) {
              _maybeAnnounce(context, state.guidanceDirection);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (_service.cameraController != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio:
                            1 / _service.cameraController!.value.aspectRatio,
                        child: CameraPreview(_service.cameraController!),
                      ),
                    ),
                  Center(
                    child: Icon(
                      _iconForDirection(state.guidanceDirection),
                      size: 96,
                      color: _colorForDirection(
                        state.guidanceDirection,
                      ).withOpacity(0.9),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color:
                                (state.connected) ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          state.connected
                              ? AppLocalizations.of(context)!.guidance_connected
                              : AppLocalizations.of(
                                context,
                              )!.guidance_disconnected,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _promptForDirection(state.guidanceDirection),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (state.guidanceDirection == 'paper_face_only')
                              ? AppLocalizations.of(
                                context,
                              )!.guidance_away_and_raise
                              : AppLocalizations.of(
                                context,
                              )!.guidance_raise_phone,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            shadows: const [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black87,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state is FailureState)
                    Positioned(
                      bottom: 64,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.red.withOpacity(0.7),
                        child: Text(
                          state.message,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (state is LoadingState)
                    Positioned.fill(
                      child: IgnorePointer(
                        ignoring: false, // يمنع التفاعل أثناء التحميل
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // طبقة Blur فوق المعاينة (الكاميرا والفلَاش يضلّوا شغّالين تحتها)
                            BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                color: Colors.black.withOpacity(0.35),
                              ),
                            ),
                            // مؤشّر تحميل + نص واضح للكفيف
                            Center(
                              child: Semantics(
                                liveRegion: true,
                                label: 'جاري المعالجة، يرجى الانتظار',
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(
                                      strokeWidth: 4,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'جاري المعالجة…',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (state.sessionId?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        'Session: ${state.sessionId}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
