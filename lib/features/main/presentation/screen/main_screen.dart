import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:navia/core/services/feedback_service.dart';

import '../../../../core/services/stt_service.dart';
import '../../../../core/services/shake_detector_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/voice_handlers/voice_handler_camera.dart';
import '../../../../core/voice_handlers/voice_handler_language.dart';
import '../../../../core/voice_handlers/voice_handler_profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../connectivity/presentation/screen/connectivity_screen.dart';
import '../../../history/presentation/screen/history_screen.dart';
import '../../../home/presentation/screen/home_screen.dart';
import '../../../pdfreader/presentation/screen/pdfreader_screen.dart';
import '../../../setting/presentation/screen/setting_screen.dart';
import '../cubit/navigation_cubit.dart';
import '../cubit/navigation_state.dart';
import '../voice/chat_compilation_loader.dart';
import '../voice/voice_router.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final List<Widget> screens = [
    HomeScreen(),
    PdfReaderScreen(),
    HistoryScreen(),
    ConnectivityScreen(), // No need for BlocProvider wrapper since it's global
    SettingScreen(),
  ];

  final STTService _sttService = STTService();
  final ShakeDetectorService _shakeDetectorService = ShakeDetectorService();
  String _lastCommand = "";
  bool _isListening = false;

  Timer? _silenceTimer;
  DateTime? _listeningStartTime;
  int _listeningDurationSec = 0;
  String _micStatusMsg = "";
  int? _lastAnnouncedIndex;

  late VoiceRouter _voiceRouter;
  late ChatCompilationLoader _loader;
  bool _inited = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // نبدأ مستشعر الهز بمجرد دخول الشاشة.
    _shakeDetectorService.start(
      onShake: (event) {
        _startListeningWithTimer();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final lang = Localizations.localeOf(context).languageCode;
    _loader = ChatCompilationLoader(lang);
    _voiceRouter = VoiceRouter(_loader);

    // نهيئ خدمة STT مرة واحدة فقط.
    if (!_inited) {
      _sttService.initialize(
        onResult: (text) {
          print("أمر صوتي مكتشف: $text");
          setState(() => _lastCommand = text);
          _startSilenceTimer();
        },
        onCompletion: (text) {
          setState(() {
            _isListening = false;
            _lastCommand = text;
            _listeningDurationSec = _listeningStartTime != null
                ? DateTime.now().difference(_listeningStartTime!).inSeconds
                : 0;
            _micStatusMsg = "⏹️ تم إيقاف المايك بعد $_listeningDurationSec ثانية (انتهاء الجلسة)";
          });
          _silenceTimer?.cancel();
          _handleVoiceCommand(text);
        },
      );
      _inited = true;
    }
  }

  void _startListeningWithTimer() async {
    FocusScope.of(context).unfocus();

    print("🎤 تم تشغيل المايك للاستماع");
    setState(() {
      _isListening = true;
      _lastCommand = "";
      _micStatusMsg = "🎤 المايك يعمل...";
      _listeningStartTime = DateTime.now();
      _listeningDurationSec = 0;
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
    print("⏹️ تم إيقاف المايك بسبب الصمت (${_listeningDurationSec} ثانية)");
    await _sttService.stopListening();
    setState(() {
      _isListening = false;
      _listeningDurationSec = _listeningStartTime != null
          ? DateTime.now().difference(_listeningStartTime!).inSeconds
          : 0;
      _micStatusMsg = "⏹️ تم إيقاف المايك بعد $_listeningDurationSec ثانية بسبب الصمت";
    });
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _shakeDetectorService.stop(); // إيقاف مستشعر الهز.
    _sttService.stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // التطبيق عاد للمقدمة - نبدأ Shake Detection
        if (!_shakeDetectorService.isActive) {
          print("📱 App resumed - Starting shake detection");
          _shakeDetectorService.start(
            onShake: (event) {
              _startListeningWithTimer();
            },
          );
        } else {
          print("📱 App resumed - Shake detection already active");
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // التطبيق ذهب للخلفية أو توقف - نوقف Shake Detection
        print("📱 App paused/inactive - Stopping shake detection");
        _shakeDetectorService.stop();
        break;
      case AppLifecycleState.hidden:
        // التطبيق مخفي - نوقف Shake Detection
        print("📱 App hidden - Stopping shake detection");
        _shakeDetectorService.stop();
        break;
    }
  }

  void _handleVoiceCommand(String text) async {
    print("[🟢] استُدعيت _handleVoiceCommand بالنص: $text");
    final navCubit = context.read<NavigationCubit>();
    final currentPage = _pageFileNameFromIndex(navCubit.state.index);
    print("[🟢] الصفحة الحالية حسب NavCubit: $currentPage, index: ${navCubit.state.index}");
    var result = await _voiceRouter.route(
      text,
      currentPage: currentPage,
    );
    print("[🟢] نتيجة VoiceRouter: $result");
    if (result['type'] == 'base') {
      var tabValue = result['tab'];
      print("[🟢] نوع الأمر: base, قيمة التاب المطلوبة: $tabValue");
      if (int.tryParse(tabValue) != null) {
        print("[🟢] سيتم الانتقال إلى التاب index = $tabValue مع popUntil");
        Navigator.of(context).popUntil((route) => route.isFirst);
        navCubit.changePage(int.parse(tabValue));
      } else {
        print("[🟢] tabValue ليس رقم!");
      }
    } else if (result['type'] == 'page' && result['data'] != null) {
      final intent = result['data'];
      final String targetPage = result['page'] ?? currentPage;
      int targetIndex = _pageIndexFromFileName(targetPage);
      if (navCubit.state.index != targetIndex) {
        print("[🟢] نحتاج للانتقال للصفحة: $targetPage (index $targetIndex)");
        navCubit.changePage(targetIndex);
        Future.delayed(const Duration(milliseconds: 300), () {
          _executeIntent(context, intent, text);
        });
      } else {
        _executeIntent(context, intent, text);
      }
    } else {
      print("[🟢] الأمر غير معروف، سيتم إعلان لم أفهم الأمر");
      _announcePage("لم أفهم الأمر");
    }
  }

  void _executeIntent(BuildContext context, Map<String, dynamic> intent, String originalText) async {
    if (await CameraVoiceHandler.handle(context, intent, originalText: originalText)) {
      print("[🟢] CameraVoiceHandler نفذ الأمر!");
      return;
    }
    if (await ProfileVoiceHandler.handle(context, intent, originalText: originalText)) {
      print("[🟢] ProfileVoiceHandler نفذ الأمر!");
      return;
    }
    if (await LanguageVoiceHandler.handle(context, intent, originalText: originalText)) return;
    print("[🟢] لم يتعرف على أي Handler للintent الحالي");
    _announcePage("لم أفهم الأمر");
  }

  Future<void> _announcePage(String pageName) async {
    FeedbackService().announce(pageName,context);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: _isListening,
      child: GestureDetector(
        onTap: () {
          if (_isListening) {
            _stopListeningDueToSilence();
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.mainGradient,
          ),
          child: BlocBuilder<NavigationCubit, NavigationState>(
            builder: (context, state) {
              if (_lastAnnouncedIndex != state.index) {
                _lastAnnouncedIndex = state.index;
                Future.delayed(const Duration(milliseconds: 200), () {
                  String pageTitle = _pageTitleFromIndex(state.index, context);
                  _announcePage(pageTitle);
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
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 100,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      ignoring: _isListening,
                      child: _buildCustomNavBar(context, state.index),
                    ),
                  ),
                  Positioned(
                    right: 20,
                    bottom: 90,
                    child: IgnorePointer(
                      ignoring: _isListening,
                      child: FloatingActionButton(
                        heroTag: "stt_fab",
                        onPressed: _startListeningWithTimer,
                        child: const Icon(Icons.mic),
                        tooltip: "فعّل التنقل الصوتي",
                      ),
                    ),
                  ),
                  Semantics(
                    excludeSemantics: true,
                    child: Visibility(
                      visible: false,
                      child: Center(
                        child: Text(
                          "الأمر الصوتي: $_lastCommand",
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x959DA540),
            offset: Offset(0, -3),
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
      BuildContext context, IconData icon, int index, int selectedIndex) {
    final isSelected = index == selectedIndex;
    final labels = [
      AppLocalizations.of(context)!.home,
      AppLocalizations.of(context)!.pdfreader,
      AppLocalizations.of(context)!.history,
      AppLocalizations.of(context)!.connectivity,
      AppLocalizations.of(context)!.setting,
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
              color: isSelected ? AppTheme.primary : Colors.grey,
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

String _pageFileNameFromIndex(int index) {
  switch (index) {
    case 0:
      return "home";
    case 1:
      return "reader";
    case 2:
      return "history";
    case 3:
      return "connectivity";
    case 4:
      return "settings";
    default:
      return "home";
  }
}

int _pageIndexFromFileName(String page) {
  switch (page) {
    case "home":
      return 0;
    case "reader":
      return 1;
    case "history":
      return 2;
    case "connectivity":
      return 3;
    case "settings":
      return 4;
    default:
      return 0;
  }
}

String _pageTitleFromIndex(int index, BuildContext context) {
  switch (index) {
    case 0:
      return AppLocalizations.of(context)!.pageHome;
    case 1:
      return AppLocalizations.of(context)!.pagePDFReader;
    case 2:
      return AppLocalizations.of(context)!.pageHistory;
    case 3:
      return AppLocalizations.of(context)!.pageConnectivity;
    case 4:
      return AppLocalizations.of(context)!.pageSettings;
    default:
      return AppLocalizations.of(context)!.pageHome;
  }
}