import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../../../l10n/app_localizations.dart';

import 'core/services/background_service_manager.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/main/presentation/cubit/navigation_cubit.dart';
import 'features/connectivity/presentation/cubit/connectivity_cubit.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    _locale = locale;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => di.sl<AuthCubit>()),
        BlocProvider<NavigationCubit>(create: (context) => di.sl<NavigationCubit>()),
        BlocProvider<ConnectivityCubit>(create: (context) => di.sl<ConnectivityCubit>()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates:const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('en'),
          Locale('ar'),
        ],
        title: 'Nabd',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
