import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenRefreshExhaustedError implements Exception {
  TokenRefreshExhaustedError(this.message);
  final String message;
  @override
  String toString() => message;
}

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _idTokenKey = 'ec.native.firebase_id_token';
  static const _expiryKey = 'ec.native.token_expiry';

  Future<void> persistToken(String idToken) async {
    final claims = _decodeJwtPayload(idToken);
    final expiry = claims?['exp'] as int?;
    await _storage.write(key: _idTokenKey, value: idToken);
    await _storage.write(
      key: _expiryKey,
      value: expiry != null ? (expiry * 1000).toString() : '',
    );
  }

  Future<String?> readToken() async {
    final token = await _storage.read(key: _idTokenKey);
    if (token == null || token.isEmpty) return null;
    if (_isExpired(token)) return null;
    return token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _idTokenKey);
    await _storage.delete(key: _expiryKey);
  }

  bool _isExpired(String token) {
    final claims = _decodeJwtPayload(token);
    final exp = claims?['exp'] as int?;
    if (exp == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return exp <= now;
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
