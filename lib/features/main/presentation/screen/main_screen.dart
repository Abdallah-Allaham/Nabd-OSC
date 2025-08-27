import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../../core/services/shake_detector_service.dart';
import '../../../../core/services/stt_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../injection_container.dart';
import '../cubit/navigation_cubit.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> screens = [
    const HomeScreen(),
    const PdfReaderScreen(),
    const HistoryScreen(),
    const ConnectivityScreen(),
    const SettingScreen(),
  ];

  final STTService _sttService = sl<STTService>();
  final ShakeDetectorService _shakeDetectorService = sl<ShakeDetectorService>();

  String _lastCommand = "";
  bool _isListening = false;
  Timer? _silenceTimer;
  DateTime? _listeningStartTime;
  String _micStatusMsg = "";
  int? _lastAnnouncedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locale = Localizations.localeOf(context).toString();
      final localizations = AppLocalizations.of(context)!;
      print("Initializing STTService with locale: $locale");
      print("pageSettings value: ${localizations.pageSettings}");
      print("pageHistory value: ${localizations.pageHistory}");
      _sttService.initialize(
        locale: locale,
        onResult: (String text) {
          _lastCommand = text;
          _handleVoiceCommand(text);
          _startSilenceTimer();
        },
        onCompletion: (String text) {
          _lastCommand = text;
          _handleVoiceCommand(text);
          _stopListeningDueToSilence();
        },
      );
    });
    _shakeDetectorService.start(onShake: (_) => _startListeningWithTimer());
  }

  void _startListeningWithTimer() async {
    _shakeDetectorService.stop();
    FocusScope.of(context).unfocus();
    HapticFeedback.vibrate();

    print("🎤 تم تشغيل المايك للاستماع");
    setState(() {
      _isListening = true;
      _lastCommand = "";
      _micStatusMsg = AppLocalizations.of(context)!.microphoneOn;
      _listeningStartTime = DateTime.now();
    });

    await _sttService.startListening();
    _startSilenceTimer();
  }

  void _startSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 10), () {
      _stopListeningDueToSilence();
    });
  }

  void _stopListeningDueToSilence() async {
    print("⏹️ تم إيقاف المايك بسبب الصمت.");
    await _sttService.stopListening();
    setState(() {
      _isListening = false;
      _micStatusMsg = AppLocalizations.of(context)!.microphoneOffSilence;
    });
    _shakeDetectorService.start(onShake: (_) => _startListeningWithTimer());
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _shakeDetectorService.stop();
    _sttService.stopListening();
    super.dispose();
  }

  void _handleVoiceCommand(String text) {
    print("جارٍ تحليل الأمر الصوتي: $text");
    final textLower = text.toLowerCase().trim();
    final localizations = AppLocalizations.of(context)!;

    final Map<int, List<String>> commands = {
      0: [
        localizations.pageHome.toLowerCase(),
        "الرئيسية",
        "home",
        "هوم",
        "الصفحة الرئيسية",
        "الصفحه الرئيسيه",
      ],
      1: [
        localizations.pagePDFReader.toLowerCase(),
        "القارئ",
        "reader",
        "pdf",
        "قراءة",
        "بي دي اف",
      ],
      2: [
        localizations.pageHistory.toLowerCase(),
        "السجل",
        "history",
        "هيستوري",
        "سجل",
      ],
      3: [
        localizations.pageConnectivity.toLowerCase(),
        "الاتصال",
        "connectivity",
        "كونكت",
        "كونكتيفيتي",
        "الاتصالات",
      ],
      4: [
        localizations.pageSettings.toLowerCase(),
        "الاعدادات",
        "الإعدادات",
        "settings",
        "ستنجز",
        "setting",
        "اعدادات",
        "الإعدادات ",
        "الاعدادات ",
      ],
    };

    print("Available commands: $commands");

    final profileCommands = [
      localizations.pageProfile.toLowerCase(),
      "الملف الشخصي",
      "الحساب",
      "بروفايل",
      "profile",
      "account",
      "أدخل على الحساب",
      "افتح حسابي",
    ];

    for (final key in profileCommands) {
      if (textLower.contains(key)) {
        print("تطابق أمر الملف الشخصي: $key");
        //Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        //_announcePage(localizations.profileOpened);
        return;
      }
    }

    for (final entry in commands.entries) {
      for (final key in entry.value) {
        if (textLower == key) {
          print("تطابق الأمر: $key، الانتقال إلى الصفحة: ${entry.key}");
          context.read<NavigationCubit>().changePage(entry.key);
          String pageTitle = _getPageTitle(entry.key, context);
          _announcePage(localizations.pageOpened(pageTitle));
          return;
        }
      }
    }
    print("لم يتم العثور على تطابق للأمر: $textLower");
  }

  Future<void> _announcePage(String pageName) async {
    SemanticsService.announce(pageName, TextDirection.rtl);
  }

  @override
  Widget build(BuildContext context) {
    final appGradient = Theme.of(context).extension<AppGradient>();

    return ExcludeSemantics(
      excluding: _isListening,
      child: GestureDetector(
        onTap: () {
          if (_isListening) {
            _stopListeningDueToSilence();
          }
        },
        child: Container(
          decoration: BoxDecoration(gradient: appGradient?.background),
          child: BlocBuilder<NavigationCubit, NavigationState>(
            builder: (context, state) {
              if (_lastAnnouncedIndex != state.index) {
                _lastAnnouncedIndex = state.index;
                Future.delayed(const Duration(milliseconds: 200), () {
                  String pageTitle = _getPageTitle(state.index, context);
                  _announcePage(
                    AppLocalizations.of(context)!.pageOpened(pageTitle),
                  );
                });
              }
              return Stack(
                children: [
                  Scaffold(
                    backgroundColor: Colors.transparent,
                    body: screens[state.index],
                  ),
                  if (_isListening)
                    ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withOpacity(0.01),
                    ),
                  if (_isListening)
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildCustomNavBar(context, state.index),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 90,
                    child: IgnorePointer(
                      ignoring: _isListening,
                      child: FloatingActionButton(
                        heroTag: "stt_fab",
                        onPressed: _startListeningWithTimer,
                        tooltip: "فعّل التنقل الصوتي",
                        child: const Icon(Icons.mic),
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

  Widget _buildCustomNavBar(BuildContext context, int selectedIndex) {
    return Container(
      height: 74,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.textLight,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0x959DA540),
            offset: const Offset(0, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _navItem(context, Icons.home_outlined, 0, selectedIndex),
            _navItem(context, Icons.picture_as_pdf_outlined, 1, selectedIndex),
            _navItem(context, Icons.history_outlined, 2, selectedIndex),
            _navItem(context, Icons.compare_arrows_outlined, 3, selectedIndex),
            _navItem(context, Icons.settings_outlined, 4, selectedIndex),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context,
      IconData icon,
      int index,
      int selectedIndex,
      ) {
    final localizations = AppLocalizations.of(context)!;
    final isSelected = index == selectedIndex;
    final labels = [
      localizations.pageHome,
      localizations.pagePDFReader,
      localizations.pageHistory,
      localizations.pageConnectivity,
      localizations.pageSettings,
    ];
    return Semantics(
      button: true,
      selected: isSelected,
      label: labels[index],
      child: GestureDetector(
        onTap: () => context.read<NavigationCubit>().changePage(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppTheme.accent : Colors.grey,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

String _getPageTitle(int index, BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  switch (index) {
    case 0:
      return localizations.pageHome;
    case 1:
      return localizations.pagePDFReader;
    case 2:
      return localizations.pageHistory;
    case 3:
      return localizations.pageConnectivity;
    case 4:
      return localizations.pageSettings;
    default:
      return "";
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.pageHome));
  }
}

class PdfReaderScreen extends StatelessWidget {
  const PdfReaderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.pagePDFReader));
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.pageHistory));
  }
}

class ConnectivityScreen extends StatelessWidget {
  const ConnectivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.pageConnectivity));
  }
}

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.pageSettings));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(AppLocalizations.of(context)!.pageProfile));
  }
}