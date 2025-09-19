import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';
import '../../../connectivity/data/bridge/connectivity_channel.dart';

class ConnectivityScreen extends StatefulWidget {
  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    ConnectivityChannel.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      // Start the flow on first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ConnectivityCubit>().startFlow(context);
      });
    }
  }

  @override
  void dispose() {
    ConnectivityChannel.setFlagSecure(false);
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
    final cubit = context.read<ConnectivityCubit>();
    final jsonData = cubit.getFinalJson();
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        QrImageView(
          data: jsonData,
          version: QrVersions.auto,
          size: 200.0,
          semanticsLabel: 'Wi-Fi QR Code',
        ),
        const SizedBox(height: 20),
        Text(
          'SSID: ${state.ssid}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        Text(
          'Password: ${state.password}',
          style: const TextStyle(fontSize: 16),
        ),
        if (state.uid != null) ...[
          const SizedBox(height: 10),
          Text(
            'UID: ${state.uid}',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ],
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
