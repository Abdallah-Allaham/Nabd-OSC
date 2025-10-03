import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/connectivity_cubit.dart';
import '../cubit/connectivity_state.dart';
import '../../../connectivity/data/bridge/connectivity_channel.dart';

class ConnectivityScreen extends StatefulWidget {
  const ConnectivityScreen({super.key});

  @override
  State<ConnectivityScreen> createState() => _ConnectivityScreenState();
}

class _ConnectivityScreenState extends State<ConnectivityScreen> {
  final FeedbackService _feedbackService = FeedbackService();
  bool _flowStarted = false;

  @override
  void initState() {
    super.initState();
    ConnectivityChannel.initialize();
    _setupConnectivityChannel();
    
    if (!_flowStarted) {
      _flowStarted = true;
      _runConnectivityFlow();
    }
  }

  void _setupConnectivityChannel() {
    ConnectivityChannel.setMethodCallHandler((method, arguments) {
      switch (method) {
        case 'failure':
          _onFailure(arguments as Map<String, dynamic>);
          break;
        default:
          // تجاهل كل الطلبات الأخرى - نحتاج فقط رسالة النجاح
          context.read<ConnectivityCubit>().showSuccess();
          break;
      }
    });
  }

  Future<void> _runConnectivityFlow() async {
    // فتح إعدادات الواي فاي وتشغيل accessibility service
    await ConnectivityChannel.openWifiSettings();
    await Future.delayed(const Duration(milliseconds: 200));
    await ConnectivityChannel.invoke('a11y_start');
    
    // عرض رسالة النجاح
    context.read<ConnectivityCubit>().showSuccess();
  }


  void _onFailure(Map err) async {
    // Show error
    if (mounted) {
      context.read<ConnectivityCubit>().showError(err['reason'] as String? ?? 'UNKNOWN');
    }
  }



  @override
  void dispose() {
    // إيقاف accessibility service
    ConnectivityChannel.invoke('a11y_stop');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivitySuccess) {
          _feedbackService.announce(AppLocalizations.of(context)!.operation_successful, context);
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
    if (state is ConnectivitySuccess) {
      return _buildSuccessMessage(context);
    } else if (state is ConnectivityError) {
      return _buildErrorMessage(context, state);
    } else {
      return _buildLoadingMessage(context, state);
    }
  }

  Widget _buildSuccessMessage(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.mainGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              
              // Success Title
              Text(
                AppLocalizations.of(context)!.operation_successful,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Success Message
              Text(
                AppLocalizations.of(context)!.wifi_settings_opened,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.close,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.connectivity,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

