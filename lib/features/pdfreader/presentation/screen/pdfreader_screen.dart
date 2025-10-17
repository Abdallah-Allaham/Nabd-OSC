import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'dart:io' show Platform;
import 'package:navia/core/services/feedback_service.dart'; // إضافة الفيدباك

class PickedDoc {
  final String uri;
  final String name;
  final int? size;
  final String mime;

  PickedDoc({
    required this.uri,
    required this.name,
    required this.size,
    required this.mime,
  });
}

class PdfReaderScreen extends StatefulWidget {
  @override
  _PdfReaderScreenState createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  static const _metaCh = MethodChannel('saf_meta');
  static const _allowedExt = {'pdf', 'doc', 'docx'};
  static const _allowedMimes = {
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };

  final feedback = FeedbackService(); // إضافة هنا

  Future<void> _announce(String msg, {String? feedbackType}) async {
    if (!mounted) return;
    switch (feedbackType) {
      case 'success':
        feedback.playSuccessTone();
        feedback.announce(msg, context);
        feedback.vibrateLight();
        break;
      case 'fail':
        feedback.playFailureTone();
        feedback.announce(msg, context);
        feedback.vibrateHeavy();
        break;
      default:
        feedback.announce(msg, context);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPicker() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
      type: FileType.custom,
      allowedExtensions: _allowedExt.toList(),
    );
    if (res == null) {
      await _announce('تم الإلغاء.', feedbackType: 'fail');
      return;
    }

    final f = res.files.single;
    final path = f.path ?? '';
    String mime = '';
    if (Platform.isAndroid && path.startsWith('content://')) {
      mime = await _getMimeAndroid(path);
    }
    mime = mime.isNotEmpty ? mime : (lookupMimeType(f.name) ?? '');

    final ext = (f.extension ?? '').toLowerCase();
    final okByExt = _allowedExt.contains(ext);
    final okByMime = mime.isEmpty ? true : _allowedMimes.contains(mime);
    if (!(okByExt && okByMime)) {
      await _announce(
        'نوع الملف غير مدعوم. الرجاء اختيار PDF أو Word فقط.',
        feedbackType: 'fail',
      );
      return _openPicker();
    }

    if (f.size != null && f.size! > 1024 * 500) {
      await _announce(
        'الملف كبير جدًا. الحد الأقصى المسموح: 500 كيلوبايت.',
        feedbackType: 'fail',
      );
      return _openPicker();
    }

    await _announce('تم اختيار الملف بنجاح!', feedbackType: 'success');
    final picked = PickedDoc(uri: path, name: f.name, size: f.size, mime: mime);
    debugPrint(
      'Picked -> uri=${picked.uri} | name=${picked.name} | size=${picked.size} | mime=${picked.mime}',
    );
  }

  Future<String> _getMimeAndroid(String contentUri) async {
    try {
      final mt = await _metaCh.invokeMethod<String>('getMimeType', {
        'uri': contentUri,
      });
      return mt ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _openPicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick PDF/Word (Selection Only)')),
      body: Center(
        child: Semantics(
          label: 'Pick a document. Allowed types: PDF or Word.',
          button: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text('Choosing a file...')],
          ),
        ),
      ),
    );
  }
}
