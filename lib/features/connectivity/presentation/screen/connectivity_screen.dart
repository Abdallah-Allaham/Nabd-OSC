import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';
import '../../../connectivity/data/bridge/connectivity_channel.dart';
import '../widgets/wifi_qr_widget.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _flowStarted = false;
  bool _settingsLaunchedThisSession = false;
  bool _a11yStartedThisSession = false;

  @override
  void initState() {
    super.initState();
    ConnectivityChannel.initialize();
    _setupConnectivityChannel();
    // Enable FLAG_SECURE when showing QR
    ConnectivityChannel.setFlagSecure(true);
    
    if (!_flowStarted) {
      _flowStarted = true;
      _runConnectivityFlow();
    }
  }

  void _setupConnectivityChannel() {
    ConnectivityChannel.setMethodCallHandler((method, arguments) {
      switch (method) {
        case 'settings_list_visible':
          // nothing extra (prewarm already started)
          break;
        case 'qr_visible':
          _onQrVisible();
          break;
        case 'capture_blocked':
          _handleCaptureBlocked();
          break;
        case 'screen_capture_ready':
          _onScreenCaptureReady();
          break;
        case 'qr_parsed':
          _onQrParsed(arguments as Map<String, dynamic>);
          break;
        case 'request_password':
          _onPasswordRequest(arguments as Map<String, dynamic>);
          break;
        case 'failure':
          _onFailure(arguments as Map<String, dynamic>);
          break;
        default:
          break;
      }
    });
  }

  Future<void> _runConnectivityFlow() async {
    // 1) Start flow
    await ConnectivityChannel.connectivityFlowStart();

    // Clear cache when starting new flow
    context.read<ConnectivityCubit>().clearCache();

    // 2) Ensure media projection ready
    final ready = await ConnectivityChannel.isScreenCaptureReady();
    if (!ready) {
      final hasPermission = await ConnectivityChannel.requestScreenCapture();
      if (!hasPermission) {
        _showFailure('SCREEN_CAPTURE_PERMISSION_DENIED');
        return;
      }
      // Wait for permission to be granted
      return;
    }

    // 3) Open settings, then prewarm and start a11y
    await ConnectivityChannel.openWifiSettings();
    await Future.delayed(const Duration(milliseconds: 200));
    await ConnectivityChannel.prewarmStart();
    await ConnectivityChannel.invoke('a11y_start');
  }

  Future<void> _onScreenCaptureReady() async {
    await _openSettingsAndStartA11y();
  }

  Future<void> _openSettingsAndStartA11y() async {
    if (!_settingsLaunchedThisSession) {
      _settingsLaunchedThisSession = true;
      _feedbackService.announce(AppLocalizations.of(context)!.opening_wifi_settings, context);
      await ConnectivityChannel.openWifiSettings();
    }
    if (!_a11yStartedThisSession) {
      _a11yStartedThisSession = true;
      await Future.delayed(const Duration(milliseconds: 250));
      await ConnectivityChannel.invoke('a11y_start');
    }
  }

  void _onQrVisible() async {
    // give a short beat to ensure a new frame is available
    await Future.delayed(const Duration(milliseconds: 250));
    await ConnectivityChannel.captureFromPrewarm(); // results will come via qr_parsed / failure
  }

  void _onQrParsed(Map data) async {
    // Stop prewarm and a11y, end flow
    await ConnectivityChannel.prewarmStop();
    await ConnectivityChannel.invoke('a11y_stop');
    await ConnectivityChannel.connectivityFlowEnd();
    
    if (mounted) {
      // Update cubit with the parsed data to show the new QR code
      context.read<ConnectivityCubit>().updateWithParsedData(
        data['ssid'] as String, 
        data['password'] as String
      );
    }
  }

  void _onPasswordRequest(Map data) async {
    // Get SSID and request password from system
    final ssid = data['ssid'] as String;
    if (ssid.isNotEmpty) {
      final password = await ConnectivityChannel.getWifiPassword(ssid);
      if (password.isNotEmpty) {
        // We have both SSID and password, update the cubit
        context.read<ConnectivityCubit>().updateWithParsedData(ssid, password);
        // Stop the flow
        await ConnectivityChannel.invoke('a11y_stop');
        await ConnectivityChannel.connectivityFlowEnd();
      } else {
        // System couldn't get password, ask user for screenshot permission
        _showScreenshotPermissionDialog(ssid);
      }
    } else {
      // No SSID, try screenshot approach
      _onQrVisible();
    }
  }

  void _showScreenshotPermissionDialog(String ssid) async {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Screenshot Permission Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To extract the WiFi password for "$ssid", we need to take a screenshot of the WiFi settings screen. This will help us read the password automatically.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Do you want to allow screenshot capture?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // User declined, show fallback message
                _showFallbackMessage(ssid);
              },
              child: const Text('No, Skip'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // User agreed, try screenshot approach
                _onQrVisible();
              },
              child: const Text('Yes, Allow'),
            ),
          ],
        );
      },
    );
  }

  void _showFallbackMessage(String ssid) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Manual Input Required'),
          content: Text(
            'Since screenshot capture was declined, you can manually create a QR code for "$ssid" by entering the password in the app settings.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to settings or show manual QR creation
                _navigateToManualQrCreation(ssid);
              },
              child: const Text('Create QR Manually'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToManualQrCreation(String ssid) {
    // For now, just show a placeholder - you can implement manual QR creation here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Manual QR creation for "$ssid" - Feature coming soon'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onFailure(Map err) async {
    // Stop prewarm and a11y, end flow
    await ConnectivityChannel.prewarmStop();
    await ConnectivityChannel.invoke('a11y_stop');
    await ConnectivityChannel.connectivityFlowEnd();
    
    if (mounted) {
      _showFailure(err['reason'] as String? ?? 'UNKNOWN');
    }
  }

  void _showFailure(String reason) {
    // Update cubit with failure - the cubit will handle the state update
    context.read<ConnectivityCubit>().handleFailure(reason);
  }

  void _handleCaptureBlocked() {
    // Stop prewarm and a11y, end flow
    ConnectivityChannel.prewarmStop();
    ConnectivityChannel.invoke('a11y_stop');
    ConnectivityChannel.connectivityFlowEnd();
    
    // Show fallback dialog
    _showFallbackDialog();
  }

  void _showFallbackDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Capture Blocked'),
          content: const Text(
            'Your device blocks capturing Settings. Open in-app camera to scan the QR on screen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // User declined, show failure
                _showFailure('CAPTURE_BLOCKED');
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Open ML Kit camera preview to scan QR manually
                _showFailure('MANUAL_SCAN_NOT_IMPLEMENTED');
              },
              child: const Text('Open Camera'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Stop accessibility service session
    ConnectivityChannel.invoke('a11y_stop');
    ConnectivityChannel.setFlagSecure(false);
    // End connectivity flow
    ConnectivityChannel.connectivityFlowEnd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityCapturing) {
          _feedbackService.announce('capturing', context);
        } else if (state is ConnectivityReady) {
          // Enable FLAG_SECURE when QR is visible
          ConnectivityChannel.setFlagSecure(true);
          _feedbackService.announce('code_ready', context);
        } else if (state is ConnectivityFallback) {
          _feedbackService.announce('fallback_use_system_qr', context);
        }
      },
      child: BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) {
          return Center(
            child: Semantics(
              header: true,
              label: AppLocalizations.of(context)!.connectivity,
              excludeSemantics: false,
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, ConnectivityState state) {
    if (state is ConnectivityReady) {
      return _buildQrCode(context, state);
    } else if (state is ConnectivityFallback) {
      return _buildFallbackMessage(context);
    } else if (state is ConnectivityError) {
      return _buildErrorMessage(context, state);
    } else {
      return _buildLoadingMessage(context, state);
    }
  }

  Widget _buildQrCode(BuildContext context, ConnectivityReady state) {
    return WifiQrWidget(
      ssid: state.ssid,
      password: state.password,
      uid: state.uid,
    );
  }

  Widget _buildFallbackMessage(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.warning, size: 48, color: Colors.orange),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.fallback_use_system_qr,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, ConnectivityError state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(
          'Error: ${state.reason}',
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingMessage(BuildContext context, ConnectivityState state) {
    String message;
    
    if (state is ConnectivityOpeningSettings) {
      message = AppLocalizations.of(context)!.opening_wifi_settings;
    } else if (state is ConnectivityCapturing) {
      message = AppLocalizations.of(context)!.capturing;
    } else {
      message = AppLocalizations.of(context)!.connectivity;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

