import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

class ChatCompilationLoader {
  final String locale;
  Map<String, dynamic>? baseYaml;
  Map<String, dynamic>? pageYaml;

  ChatCompilationLoader(this.locale);

  Future<void> loadBase() async {
    final data = await rootBundle.loadString('assets/chat_compilation/$locale/base.yaml');
    final yamlMap = loadYaml(data);
    baseYaml = _toMap(yamlMap);
    print(">> محتوى baseYaml: $baseYaml");
  }

  Future<void> loadPage(String page) async {
    final data = await rootBundle.loadString('assets/chat_compilation/$locale/pages/$page.yaml');
    final yamlMap = loadYaml(data);
    pageYaml = _toMap(yamlMap);
    print(">> محتوى pageYaml: $pageYaml");

  }

  Map<String, dynamic> _toMap(dynamic yaml) {
    if (yaml is YamlMap) {
      return Map<String, dynamic>.from(yaml);
    }
    return {};
  }
}
