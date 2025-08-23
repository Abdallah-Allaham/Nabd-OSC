import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/background_service_manager.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");

  final String picoVoiceAccessKey = dotenv.env['PICOVOICE_ACCESS_KEY']!;
  await di.init(accessKey: picoVoiceAccessKey);
  BackgroundServiceManager();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => di.sl<AuthCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Nabd App',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
