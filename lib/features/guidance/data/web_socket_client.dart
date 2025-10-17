import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final String url;

  WebSocketClient({required this.url});

  Future<void> connect(Function(dynamic) onMessage, Function(String) onError, {Function()? onDone}) async {
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(url));
      _channel!.stream.listen(
        onMessage,
        onError: (error) {
          onError("WebSocket Error: $error");
        },
        onDone: () {
          if (onDone != null) onDone();
          onError("WebSocket connection closed");
        },
      );
    } catch (e) {
      onError("WebSocket connection failed: $e");
    }
  }

  void sendText(Object data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void sendBinary(List<int> data) {
    _channel?.sink.add(data);
  }

  void close() {
    _channel?.sink.close();
  }
}


