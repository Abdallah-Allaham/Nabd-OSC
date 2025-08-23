class ServerException implements Exception {
  final String message;
  const ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class VoiceIdException implements Exception {
  final String message;
  const VoiceIdException(this.message);

  @override
  String toString() => 'VoiceIdException: $message';
}