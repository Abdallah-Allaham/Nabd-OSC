import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'dart:io' show Platform;

class PickedDoc {
  final String uri;
  final String name;
  final int? size;
  final String mime;
  PickedDoc({required this.uri, required this.name, required this.size, required this.mime});
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

  Future<void> _announce(String msg) async {
    if (!mounted) return;
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
      await _announce('Cancelled.');
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
      await _announce('Unsupported type. Please select PDF or Word only.');
      return _openPicker();
    }

    // Validate file size (optional)
    if (f.size != null && f.size! > 1024 * 500) {  // Set size limit to 500 KB
      await _announce('File too large. Max allowed size: 500 KB');
      return _openPicker();
    }

    await _announce('File selected.');
    final picked = PickedDoc(uri: path, name: f.name, size: f.size, mime: mime);
    debugPrint('Picked -> uri=${picked.uri} | name=${picked.name} | size=${picked.size} | mime=${picked.mime}');
  }

  Future<String> _getMimeAndroid(String contentUri) async {
    try {
      final mt = await _metaCh.invokeMethod<String>('getMimeType', {'uri': contentUri});
      return mt ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    // Open the picker directly when the page loads
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
            children: [
              Text('Choosing a file...'),
              // This button is no longer necessary, the file picker opens automatically
              // ElevatedButton.icon(
              //   onPressed: _openPicker,
              //   icon: const Icon(Icons.file_open),
              //   label: const Text('Pick Document'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
