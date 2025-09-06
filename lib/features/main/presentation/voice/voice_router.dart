import 'chat_compilation_loader.dart';

class VoiceRouter {
  final ChatCompilationLoader loader;
  final List<String> allPageNames = [
    'home',
    'reader',
    'history',
    'connectivity',
    'settings',
  ];

  VoiceRouter(this.loader);

  Future<Map<String, dynamic>> route(String userText,
      {String currentPage = 'home'}) async {
    print('================= VoiceRouter ===============');
    print('Received text: $userText');
    print('Current page: $currentPage');

    if (loader.baseYaml == null) {
      print('[Base] Loading base.yaml ...');
      await loader.loadBase();
    }
    print('[Base] Checking in base...');
    var baseOutput = _checkBase(userText);
    if (baseOutput != loader.baseYaml?['unknown_reply'] && baseOutput != 'try again') {
      print('[Base] FOUND → $baseOutput');
      return {'type': 'base', 'tab': baseOutput};
    } else {
      print('[Base] Not found.');
    }


    print('[Page] Loading $currentPage.yaml ...');
    await loader.loadPage(currentPage);
    print('[Page] Checking in page: $currentPage');
    var pageOutput = _checkPage(userText);
    if (pageOutput.isNotEmpty) {
      print('[Page] FOUND in $currentPage → $pageOutput');
      return {'type': 'page', 'page': currentPage, 'data': pageOutput};
    } else {
      print('[Page] Not found in $currentPage.');
    }

    for (var pageName in allPageNames) {
      if (pageName == currentPage) continue;
      print('[Other Page] Loading $pageName.yaml ...');
      await loader.loadPage(pageName);
      print('[Other Page] Checking in page: $pageName');
      var otherPageOutput = _checkPage(userText);
      if (otherPageOutput.isNotEmpty) {
        print('[Other Page] FOUND in $pageName → $otherPageOutput');
        return {'type': 'page', 'page': pageName, 'data': otherPageOutput};
      } else {
        print('[Other Page] Not found in $pageName.');
      }
    }

    print('[Unknown] لم يتم العثور على أي أمر مطابق.');
    return {'type': 'unknown', 'message': 'لم أفهم، أعد الكلام'};
  }

  String _checkBase(String text) {
    final tabs = loader.baseYaml?['tabs'] ?? {};
    for (var key in tabs.keys) {
      for (var syn in List<String>.from(tabs[key])) {
        if (text.toLowerCase().contains(syn.toLowerCase())) {
          print('[Base] Match: "$syn" → $key');
          return key;
        }
      }
    }
    return loader.baseYaml?['unknown_reply'] ?? 'try again';
  }

  Map<String, dynamic> _checkPage(String text) {
    print('--- [Checking Page Intents] ---');
    final intents = loader.pageYaml?['intents'] ?? [];
    print('عدد الأوامر (intents): ${intents.length}');
    String _normalize(String s) => s.trim().toLowerCase();
    for (var intent in intents) {
      print('intent: ${intent['id']}');
      print('synonyms: ${intent['synonyms']}');
      for (var syn in List<String>.from(intent['synonyms'])) {
        print('فحص المرادف: "$syn" مع "$text"');
        if (_normalize(text) == _normalize(syn)) {
          print('[Page] Match: "$syn" → ${intent['id']}');
          return Map<String, dynamic>.from(intent);
        }
      }
    }
    return {};
  }
}
