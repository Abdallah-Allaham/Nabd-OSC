import 'dart:convert';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  final String _url = 'wss://7499c157e3ea.ngrok-free.app/ws/guidance';

  Future<void> connect(Function(dynamic) onMessage, Function(String) onError) async {
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(_url));
      _channel!.stream.listen(
        onMessage,
        onError: (error) {
          onError("WebSocket Error: $error");
        },
        onDone: () {
          onError("WebSocket connection closed");
        },
      );
    } catch (e) {
      onError("WebSocket connection failed: $e");
    }
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void close() {
    _channel?.sink.close();
  }
}
